import SwiftUI

struct MGConfigurationListView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var packetTunnelManager: MGPacketTunnelManager
    @EnvironmentObject private var configurationListManager: MGConfigurationListManager
        
    @State private var isRenameAlertPresented = false
    @State private var configurationItem: MGConfiguration?
    @State private var configurationName: String = ""
    
    @State private var location: MGConfigurationLocation?
    
    @State private var isConfirmationDialogPresented = false
    @State private var `protocol`: MGConfigurationProtocol?
    
    let current: Binding<String>
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        location = .remote
                    } label: {
                        Label("从 URL 下载", systemImage: "square.and.arrow.down.on.square")
                    }
                    Button {
                        location = .local
                    } label: {
                        Label("从文件夹导入", systemImage: "tray.and.arrow.down")
                    }
                } header: {
                    Text("导入")
                }
                Section {
                    if configurationListManager.configurations.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.largeTitle)
                                Text("暂无配置")
                            }
                            .foregroundColor(.secondary)
                            .padding()
                            Spacer()
                        }
                    } else {
                        ForEach(configurationListManager.configurations) { configuration in
                            HStack(alignment: .center, spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(configuration.attributes.alias)
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    TimelineView(.periodic(from: Date(), by: 1)) { _ in
                                        Text(configuration.attributes.leastUpdated.formatted(.relative(presentation: .numeric)))
                                            .lineLimit(1)
                                            .foregroundColor(.secondary)
                                            .font(.callout)
                                            .fontWeight(.light)
                                    }
                                }
                                Spacer()
                                if configurationListManager.downloadingConfigurationIDs.contains(configuration.id) {
                                    ProgressView()
                                }
                            }
                            .contextMenu {
                                Button {
                                    self.configurationName = configuration.attributes.alias
                                    self.configurationItem = configuration
                                    self.isRenameAlertPresented.toggle()
                                } label: {
                                    Label("重命名", systemImage: "square.and.pencil")
                                }
                                Button {
                                    Task(priority: .userInitiated) {
                                        do {
                                            try await configurationListManager.update(configuration: configuration)
                                            MGNotification.send(title: "", subtitle: "", body: "\"\(configuration.attributes.alias)\"更新成功")
                                            if configuration.id == current.wrappedValue {
                                                guard let status = packetTunnelManager.status, status == .connected else {
                                                    return
                                                }
                                                packetTunnelManager.stop()
                                                do {
                                                    try await packetTunnelManager.start()
                                                } catch {
                                                    debugPrint(error.localizedDescription)
                                                }
                                            }
                                        } catch {
                                            MGNotification.send(title: "", subtitle: "", body: "\"\(configuration.attributes.alias)\"更新失败, 原因: \(error.localizedDescription)")
                                        }
                                    }
                                } label: {
                                    Label("更新", systemImage: "arrow.triangle.2.circlepath")
                                }
                                .disabled(configurationListManager.downloadingConfigurationIDs.contains(configuration.id) || configuration.attributes.source.isFileURL)
                                Divider()
                                Button(role: .destructive) {
                                    do {
                                        try configurationListManager.delete(configuration: configuration)
                                        MGNotification.send(title: "", subtitle: "", body: "\"\(configuration.attributes.alias)\"删除成功")
                                        if configuration.id == current.wrappedValue {
                                            current.wrappedValue = ""
                                            packetTunnelManager.stop()
                                        }
                                    } catch {
                                        MGNotification.send(title: "", subtitle: "", body: "\"\(configuration.attributes.alias)\"删除失败, 原因: \(error.localizedDescription)")
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                .disabled(configurationListManager.downloadingConfigurationIDs.contains(configuration.id))
                            }
                        }
                    }
                } header: {
                    Text("配置列表")
                } footer: {
                    Text("支持 JSON、YAML、TOML 格式配置")
                }
            }
            .navigationTitle(Text("配置管理"))
            .navigationBarTitleDisplayMode(.large)
            .alert("重命名", isPresented: $isRenameAlertPresented, presenting: configurationItem) { item in
                TextField("请输入配置名称", text: $configurationName)
                Button("确定") {
                    let name = configurationName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !(name == item.attributes.alias || name.isEmpty) else {
                        return
                    }
                    do {
                        try configurationListManager.rename(configuration: item, name: name)
                    } catch {
                        MGNotification.send(title: "", subtitle: "", body: "重命名失败, 原因: \(error.localizedDescription)")
                    }
                }
                Button("取消", role: .cancel) {}
            }
            .sheet(item: $location) { location in
                MGConfigurationLoadView(location: location)
            }
            .toolbar {
                Button {
                    isConfirmationDialogPresented.toggle()
                } label: {
                    Image(systemName: "plus")
                }
                .confirmationDialog("", isPresented: $isConfirmationDialogPresented) {
                    Button(MGConfigurationProtocol.vless.description) {
                        `protocol` = .vless
                    }
                    Button(MGConfigurationProtocol.vmess.description) {
                        `protocol` = .vmess
                    }
                }
                .fullScreenCover(item: $protocol) { `protocol` in
                    MGCreateConfigurationView(protocol: `protocol`)
                }
            }
        }
    }
}

public enum MGConfigurationProtocol: String, Identifiable, CaseIterable, CustomStringConvertible {
    
    public var id: Self { self }
    
    case vless, vmess
    
    public var description: String {
        switch self {
        case .vless:
            return "VLESS"
        case .vmess:
            return "VMess"
        }
    }
}

public enum MGConfigurationNetwork: String, Identifiable, CaseIterable, CustomStringConvertible {
    
    public var id: Self { self }
    
    case tcp, kcp, ws, http, quic, grpc

    public var description: String {
        switch self {
        case .tcp:
            return "TCP"
        case .kcp:
            return "mKCP"
        case .ws:
            return "WebSocket"
        case .http:
            return "HTTP/2"
        case .quic:
            return "QUIC"
        case .grpc:
            return "gRPC"
        }
    }
}

public enum MGConfigurationEncryption: String, Identifiable, CustomStringConvertible {
    
    public var id: Self { self }
    
    case aes_128_gcm, chacha20_poly1305, auto, none, zero
    
    public var description: String {
        switch self {
        case .aes_128_gcm:
            return "AES-128-GCM"
        case .chacha20_poly1305:
            return "Chacha20-Poly1305"
        case .auto:
            return "Auto"
        case .none:
            return "None"
        case .zero:
            return "Zero"
        }
    }
    
    public static let vless: [MGConfigurationEncryption] = [.auto, .aes_128_gcm, .chacha20_poly1305, .none]
    
    public static let vmess: [MGConfigurationEncryption] = [.auto, .aes_128_gcm, .chacha20_poly1305, .none, .zero]
}

public enum MGConfigurationSecurity: String, Identifiable, CaseIterable, CustomStringConvertible {
    
    public var id: Self { self }
    
    case none, tls, reality
    
    public var description: String {
        switch self {
        case .none:
            return "None"
        case .tls:
            return "TLS"
        case .reality:
            return "Reality"
        }
    }
}

public enum MGConfigurationFlow: String, Identifiable, CaseIterable, CustomStringConvertible {
    
    public var id: Self { self }
    
    case none, xtls_rprx_vision, xtls_rprx_vision_udp443
    
    public var description: String {
        switch self {
        case .none:
            return "None"
        case .xtls_rprx_vision:
            return "XTLS-RPRX-Vision"
        case .xtls_rprx_vision_udp443:
            return "XTLS-RPRX-Vision-UDP443"
        }
    }
}

public enum MGConfigurationFingerprint: String, Identifiable, CaseIterable, CustomStringConvertible {
    
    public var id: Self { self }
    
    case chrome, firefox, safari, ios, android, edge, _360, qq, random, randomized
    
    public var description: String {
        switch self {
        case .chrome:
            return "Chrome"
        case .firefox:
            return "Firefox"
        case .safari:
            return "Safari"
        case .ios:
            return "iOS"
        case .android:
            return "Android"
        case .edge:
            return "Edge"
        case ._360:
            return "360"
        case .qq:
            return "QQ"
        case .random:
            return "Random"
        case .randomized:
            return "Randomized"
        }
    }
}

public enum MGConfigurationALPN: String, Identifiable, CaseIterable, CustomStringConvertible {
    
    public var id: Self { self }
    
    case none       = ""
    case h2         = "h2"
    case http11     = "http/1.1"
    case h2http11   = "h2,http/1.1"
    
    public var description: String {
        switch self {
        case .none:
            return "None"
        case .h2:
            return "H2"
        case .http11:
            return "HTTP/1.1"
        case .h2http11:
            return "H2,HTTP/1.1"
        }
    }
}

struct MGCreateConfigurationView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let `protocol`: MGConfigurationProtocol
        
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MGConfigurationSettingView(protocol: `protocol`)
                } header: {
                    Text("Setting")
                }
                Section {
                    MGConfigurationStreamSettingView()
                } header: {
                    Text("Stream Setting")
                }
                Section {
                    MGConfigurationMuxView()
                } header: {
                    Text("Mux")
                }
                Section {
                    LabeledContent("Description") {
                        TextField("", text: .constant(""))
                    }
                }
            }
            .lineLimit(1)
            .multilineTextAlignment(.trailing)
            .navigationTitle(Text(`protocol`.description))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct MGConfigurationEncryptionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var encryption = MGConfigurationEncryption.none
    
    let title: String
    let encryptions: [MGConfigurationEncryption]
    
    var body: some View {
        Form {
            Picker("Encryption", selection: $encryption) {
                ForEach(encryptions) { encryption in
                    Text(encryption.description)
                }
            }
            .labelsHidden()
            .pickerStyle(.inline)
        }
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: encryption) { _ in dismiss() }
    }
}


struct MGConfigurationFlowView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var flow = MGConfigurationFlow.none
    
    var body: some View {
        Form {
            Picker("Flow", selection: $flow) {
                ForEach(MGConfigurationFlow.allCases) { encryption in
                    Text(encryption.description)
                }
            }
            .labelsHidden()
            .pickerStyle(.inline)
        }
        .navigationTitle(Text("Flow"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: flow) { _ in dismiss() }
    }
}

struct MGConfigurationProtocolView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let `protocol`: Binding<MGConfigurationProtocol>
    
    var body: some View {
        Form {
            Picker("Protocol", selection: `protocol`) {
                ForEach(MGConfigurationProtocol.allCases) { `protocol` in
                    Text(`protocol`.description)
                }
            }
            .labelsHidden()
            .pickerStyle(.inline)
        }
        .navigationTitle(Text("Protocol"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: `protocol`.wrappedValue) { _ in dismiss() }
    }
}

struct MGConfigurationSettingView: View {
    
    let `protocol`: MGConfigurationProtocol
    
    var body: some View {
        switch `protocol` {
        case .vless:
            MGConfigurationVlESSView()
        case .vmess:
            MGConfigurationVMessView()
        }
    }
}

struct MGConfigurationStreamSettingView: View {
    
    var body: some View {
        NavigationLink {
            MGConfigurationNetworkView()
        } label: {
            LabeledContent("Network", value: "TPC")
        }
        NavigationLink {
            MGConfigurationSecurityView()
        } label: {
            LabeledContent("Security", value: MGConfigurationSecurity.none.description)
        }
    }
}

struct MGConfigurationMuxView: View {
    
    var body: some View {
        Toggle("Enable", isOn: .constant(false))
        LabeledContent("Concurrency") {
            TextField("", text: .constant(""))
        }
    }
}

struct MGConfigurationVlESSView: View {
    
    var body: some View {
        LabeledContent("Address") {
            TextField("", text: .constant(""))
        }
        LabeledContent("Port") {
            TextField("", text: .constant(""))
        }
        LabeledContent("UUID") {
            TextField("", text: .constant(""))
        }
        NavigationLink {
            MGConfigurationEncryptionView(title: "Encryption", encryptions: MGConfigurationEncryption.vless)
        } label: {
            LabeledContent("Encryption", value: MGConfigurationEncryption.none.description)
        }
        NavigationLink {
            MGConfigurationFlowView()
        } label: {
            LabeledContent("Flow", value: MGConfigurationFlow.none.description)
        }
    }
}

struct MGConfigurationVMessView: View {
    
    var body: some View {
        LabeledContent("Address") {
            TextField("", text: .constant(""))
        }
        LabeledContent("Port") {
            TextField("", text: .constant(""))
        }
        LabeledContent("ID") {
            TextField("", text: .constant(""))
        }
        LabeledContent("Alert ID") {
            TextField("", text: .constant(""))
        }
        NavigationLink {
            MGConfigurationEncryptionView(title: "Security", encryptions: MGConfigurationEncryption.vmess)
        } label: {
            LabeledContent("Security", value: MGConfigurationEncryption.none.description)
        }
    }
}

struct MGConfigurationNetworkView: View {
    
    @State private var network = MGConfigurationNetwork.tcp
    
    var body: some View {
        Form {
            Section {
                Picker("Network", selection: $network) {
                    ForEach(MGConfigurationNetwork.allCases) { type in
                        Text(type.description)
                    }
                }
            }
            switch network {
            case .tcp:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Path") {
                        TextField("", text: .constant(""))
                    }
                } header: {
                    Text("TCP")
                }
            case .kcp:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Path") {
                        TextField("", text: .constant(""))
                    }
                } header: {
                    Text("mKCP")
                }
            case .ws:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Path") {
                        TextField("", text: .constant(""))
                    }
                } header: {
                    Text("WebSocket")
                }
            case .http:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Path") {
                        TextField("", text: .constant(""))
                    }
                } header: {
                    Text("HTTP/2")
                }
            case .quic:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Path") {
                        TextField("", text: .constant(""))
                    }
                } header: {
                    Text("QUIC")
                }
            case .grpc:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Path") {
                        TextField("", text: .constant(""))
                    }
                } header: {
                    Text("gRPC")
                }
            }
        }
        .navigationTitle(Text("Network"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MGConfigurationSecurityView: View {
    
    @State private var security = MGConfigurationSecurity.none
    
    var body: some View {
        Form {
            Section {
                Picker("Security", selection: $security) {
                    ForEach(MGConfigurationSecurity.allCases) { type in
                        Text(type.description)
                    }
                }
            }
            switch security {
            case .tls:
                Section {
                    LabeledContent("SNI") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Fingerprint") {
                        Picker("", selection: .constant(MGConfigurationFingerprint.chrome)) {
                            ForEach(MGConfigurationFingerprint.allCases) { fingerprint in
                                Text(fingerprint.description)
                            }
                        }
                    }
                    Toggle("Allow Insecure", isOn: .constant(false))
                } header: {
                    Text("TLS")
                }
            case .reality:
                Section {
                    LabeledContent("SNI") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Fingerprint") {
                        Picker("", selection: .constant(MGConfigurationFingerprint.chrome)) {
                            ForEach(MGConfigurationFingerprint.allCases) { fingerprint in
                                Text(fingerprint.description)
                            }
                        }
                    }
                    LabeledContent("Public Key") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Short ID") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("SpiderX") {
                        TextField("", text: .constant(""))
                    }
                } header: {
                    Text("Reality")
                }
            case .none:
                EmptyView()
            }
        }
        .navigationTitle(Text("Security"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
