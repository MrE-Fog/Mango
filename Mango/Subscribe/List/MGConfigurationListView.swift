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
    @State private var `protocol`: MGConfiguration.ProtocolType?
    
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
                    Button(MGConfiguration.ProtocolType.vless.description) {
                        `protocol` = .vless
                    }
                    Button(MGConfiguration.ProtocolType.vmess.description) {
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


final class MGCreateConfigurationViewModel: ObservableObject {
    
    @Published var streamSettings = MGConfiguration.StreamSettings()
    @Published var mux = MGConfiguration.Mux()
}

struct MGCreateConfigurationView: View {
    
    @ObservedObject private var vm = MGCreateConfigurationViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    let `protocol`: MGConfiguration.ProtocolType
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    switch `protocol` {
                    case .vless:
                        MGConfigurationVlESSView()
                    case .vmess:
                        MGConfigurationVMessView()
                    }
                } header: {
                    Text("Setting")
                }
                Section {
                    NavigationLink {
                        MGConfigurationNetworkView(vm: vm)
                    } label: {
                        LabeledContent("Network", value: vm.streamSettings.network.description)
                    }
                    NavigationLink {
                        MGConfigurationSecurityView(vm: vm)
                    } label: {
                        LabeledContent("Security", value: vm.streamSettings.security.description)
                    }
                } header: {
                    Text("Stream Setting")
                }
                Section {
                    Toggle("Enable", isOn: $vm.mux.enabled)
                    LabeledContent("Concurrency") {
                        TextField("", value: $vm.mux.concurrency, formatter: NumberFormatter())
                    }
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

struct MGConfigurationProtocolView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let `protocol`: Binding<MGConfiguration.ProtocolType>
    
    var body: some View {
        Form {
            Picker("Protocol", selection: `protocol`) {
                ForEach(MGConfiguration.ProtocolType.allCases) { `protocol` in
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
        Picker("Encryption", selection: .constant(MGConfiguration.Encryption.none)) {
            ForEach(MGConfiguration.Encryption.vless) { encryption in
                Text(encryption.description)
            }
        }
        Picker("Flow", selection: .constant(MGConfiguration.Flow.none)) {
            ForEach(MGConfiguration.Flow.allCases) { encryption in
                Text(encryption.description)
            }
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
        Picker("Encryption", selection: .constant(MGConfiguration.Encryption.none)) {
            ForEach(MGConfiguration.Encryption.vmess) { encryption in
                Text(encryption.description)
            }
        }
    }
}

struct MGConfigurationNetworkView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
        
    var body: some View {
        Form {
            Section {
                Picker("Network", selection: $vm.streamSettings.network) {
                    ForEach(MGConfiguration.Network.allCases) { type in
                        Text(type.description)
                    }
                }
            }
            switch vm.streamSettings.network {
            case .tcp:
                EmptyView()
            case .kcp:
                Section {
                    LabeledContent("MTU") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("TTI") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Uplink Capacity") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Downlink Capacity") {
                        TextField("", text: .constant(""))
                    }
                    Toggle("Congestion", isOn: .constant(false))
                    LabeledContent("Read Buffer Size") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Write Buffer Size") {
                        TextField("", text: .constant(""))
                    }
                    Picker("Header Type", selection: .constant(MGConfiguration.HeaderType.none)) {
                        ForEach(MGConfiguration.HeaderType.allCases) { type in
                            Text(type.description)
                        }
                    }
                    LabeledContent("Seed") {
                        TextField("", text: .constant(""))
                    }
                }
            case .ws:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Path") {
                        TextField("", text: .constant(""))
                    }
                }
            case .http:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: .constant(""))
                    }
                    LabeledContent("Path") {
                        TextField("", text: .constant(""))
                    }
                }
            case .quic:
                Section {
                    Picker("Security", selection: .constant(MGConfiguration.Encryption.none)) {
                        ForEach(MGConfiguration.Encryption.quic) { encryption in
                            Text(encryption.description)
                        }
                    }
                    LabeledContent("Key") {
                        TextField("", text: .constant(""))
                    }
                    Picker("Header Type", selection: .constant(MGConfiguration.HeaderType.none)) {
                        ForEach(MGConfiguration.HeaderType.allCases) { type in
                            Text(type.description)
                        }
                    }
                }
            case .grpc:
                Section {
                    LabeledContent("Service Name") {
                        TextField("", text: .constant(""))
                    }
                    Toggle("Multi-Mode", isOn: .constant(false))
                }
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
        .navigationTitle(Text("Network"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MGConfigurationSecurityView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Security", selection: $vm.streamSettings.security) {
                    ForEach(MGConfiguration.Security.allCases) { type in
                        Text(type.description)
                    }
                }
            }
            switch vm.streamSettings.security {
            case .tls:
                Section {
                    LabeledContent("Server Name") {
                        TextField("", text: $vm.streamSettings.tlsSettings.serverName)
                    }
                    LabeledContent("Fingerprint") {
                        Picker("", selection: $vm.streamSettings.tlsSettings.fingerprint) {
                            ForEach(MGConfiguration.Fingerprint.allCases) { fingerprint in
                                Text(fingerprint.description)
                            }
                        }
                    }
                    Toggle("Allow Insecure", isOn: $vm.streamSettings.tlsSettings.allowInsecure)
                }
            case .reality:
                Section {
                    LabeledContent("Server Name") {
                        TextField("", text: $vm.streamSettings.realitySettings.serverName)
                    }
                    LabeledContent("Fingerprint") {
                        Picker("", selection: $vm.streamSettings.realitySettings.fingerprint) {
                            ForEach(MGConfiguration.Fingerprint.allCases) { fingerprint in
                                Text(fingerprint.description)
                            }
                        }
                    }
                    LabeledContent("Public Key") {
                        TextField("", text: $vm.streamSettings.realitySettings.publicKey)
                    }
                    LabeledContent("Short ID") {
                        TextField("", text: $vm.streamSettings.realitySettings.shortId)
                    }
                    LabeledContent("SpiderX") {
                        TextField("", text: $vm.streamSettings.realitySettings.spiderX)
                    }
                }
            case .none:
                EmptyView()
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
        .navigationTitle(Text("Security"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
