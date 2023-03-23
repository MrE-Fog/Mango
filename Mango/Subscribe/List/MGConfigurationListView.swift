import SwiftUI
import CodeScanner

extension MGConfiguration {
    
    var typeString: String {
        if let pt = self.attributes.source.scheme.flatMap(MGConfiguration.ProtocolType.init(rawValue:)) {
            return pt.description
        } else {
            if self.attributes.source.isFileURL {
                return "本地"
            } else {
                return "远程"
            }
        }
    }
}

fileprivate extension MGConfiguration {
    
    var isUserCreated: Bool {
        self.attributes.source.scheme.flatMap(MGConfiguration.ProtocolType.init(rawValue:)) != nil
    }
    
    var isLocal: Bool {
        self.attributes.source.isFileURL || self.isUserCreated
    }
}

private struct MGConfigurationEditModel: Identifiable {
    
    let id: UUID
    let name: String
    let type: MGConfiguration.ProtocolType
    let model: MGConfiguration.Model
    
    init(configuration: MGConfiguration) throws {
        guard let id = UUID(uuidString: configuration.id) else {
            throw NSError.newError("获取唯一标识失败")
        }
        guard let type = configuration.attributes.source.scheme.flatMap(MGConfiguration.ProtocolType.init(rawValue:)) else {
            throw NSError.newError("不支持的类型")
        }
        self.id = id
        self.name = configuration.attributes.alias
        self.type = type
        let fileURL = MGConstant.configDirectory.appending(component: "\(configuration.id)/config.\(MGConfigurationFormat.json.rawValue)")
        let data = try Data(contentsOf: fileURL)
        self.model = try JSONDecoder().decode(MGConfiguration.Model.self, from: data)
    }
    
    init(code: String) throws {
        guard let components = URLComponents(string: code) else {
            throw NSError.newError("解析失败")
        }
        guard let type = components.scheme.flatMap(MGConfiguration.ProtocolType.init(rawValue:)), type != .shadowsocks, type != .shadowsocks else {
            throw NSError.newError("未知的协议类型")
        }
        guard type != .shadowsocks, type != .shadowsocks else {
            throw NSError.newError("暂不支持\(type.description)")
        }
        guard let id = components.user, !id.isEmpty else {
            throw NSError.newError("用户 ID 不存在")
        }
        guard let host = components.host, !host.isEmpty else {
            throw NSError.newError("服务器的域名或 IP 地址不存在")
        }
        guard let port = components.port, (1...65535).contains(port) else {
            throw NSError.newError("服务器的端口号不合法")
        }
        let mapping = (components.queryItems ?? []).reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
        }
        var model = MGConfiguration.Model(network: .tcp, security: .none)
        switch type {
        case .vless:
            model.vless = MGConfiguration.VLESS()
            model.vless?.users[0].id = id
            model.vless?.address = host
            model.vless?.port = port
            if let encryption = mapping["encryption"] {
                if encryption.isEmpty {
                    throw NSError.newError("加密算法存在但为空")
                } else {
                    model.vless?.users[0].encryption = encryption
                }
            }
            if let flow = mapping["flow"] {
                if flow.isEmpty {
                    throw NSError.newError("流控存在但为空")
                } else {
                    if let value = MGConfiguration.Flow(rawValue: flow) {
                        model.vless?.users[0].flow = value
                    } else {
                        throw NSError.newError("不支持的流控: \(flow)")
                    }
                }
            }
        case .vmess:
            model.vmess = MGConfiguration.VMess()
            model.vmess?.users[0].id = id
            model.vmess?.address = host
            model.vmess?.port = port
            if let encryption = mapping["encryption"] {
                if encryption.isEmpty {
                    throw NSError.newError("加密算法存在但为空")
                } else {
                    if let value = MGConfiguration.Encryption(rawValue: encryption) {
                        model.vmess?.users[0].security = value
                    } else {
                        throw NSError.newError("不支持的加密算法: \(encryption)")
                    }
                }
            }
        case .trojan, .shadowsocks:
            fatalError()
        }
        if let netowrk = mapping["type"] {
            if let value = MGConfiguration.Transport(rawValue: netowrk) {
                model.network = value
            } else {
                throw NSError.newError("不支持的传输方式: \(netowrk)")
            }
        } else {
            model.network = .tcp
        }
        switch model.network {
        case .tcp:
            model.tcp = MGConfiguration.StreamSettings.TCP()
        case .kcp:
            model.kcp = MGConfiguration.StreamSettings.KCP()
            model.kcp?.header.type = mapping["headerType"].flatMap(MGConfiguration.HeaderType.init(rawValue:)) ?? .none
            model.kcp?.seed = mapping["seed"] ?? ""
        case .ws:
            model.ws = MGConfiguration.StreamSettings.WS()
            if let sni = mapping["host"] {
                if sni.isEmpty {
                    throw NSError.newError("WS Host 存在但为空")
                } else {
                    model.ws?.headers = ["Host": sni]
                }
            } else {
                model.ws?.headers = ["Host": host]
            }
            if let value = mapping["path"] {
                if value.isEmpty {
                    throw NSError.newError("WS Path 存在但为空")
                } else {
                    model.ws?.path = value
                }
            }
        case .http:
            model.http = MGConfiguration.StreamSettings.HTTP()
            if let sni = mapping["host"] {
                if sni.isEmpty {
                    throw NSError.newError("HTTP2 Host 存在但为空")
                } else {
                    model.http?.host = [sni]
                }
            } else {
                model.http?.host = [host]
            }
            if let value = mapping["path"] {
                if value.isEmpty {
                    throw NSError.newError("HTTP2 Path 存在但为空")
                } else {
                    model.http?.path = value
                }
            }
        case .quic:
            model.quic = MGConfiguration.StreamSettings.QUIC()
            model.quic?.security = mapping["quicSecurity"].flatMap(MGConfiguration.Encryption.init(rawValue:)) ?? .none
            model.quic?.key = mapping["key"] ?? ""
            model.quic?.header.type = mapping["headerType"].flatMap(MGConfiguration.HeaderType.init(rawValue:)) ?? .none
        case .grpc:
            model.grpc = MGConfiguration.StreamSettings.GRPC()
            model.grpc?.serviceName = mapping["serviceName"] ?? ""
            model.grpc?.multiMode = mapping["mode"] == "multi"
        }
        if let security = mapping["security"] {
            if let value = MGConfiguration.Security(rawValue: security) {
                model.security = value
            } else {
                throw NSError.newError("不支持的传输安全: \(security)")
            }
        } else {
            model.security = .none
        }
        switch model.security {
        case .none:
            break
        case .tls:
            model.tls = MGConfiguration.StreamSettings.TLS()
            if let sni = mapping["sni"] {
                if sni.isEmpty {
                    throw NSError.newError("SNI 存在但为空")
                } else {
                    model.tls?.serverName = sni
                }
            } else {
                model.tls?.serverName = host
            }
            model.tls?.fingerprint = mapping["fp"].flatMap(MGConfiguration.Fingerprint.init(rawValue:)) ?? .chrome
            if let alpn = mapping["alpn"] {
                if alpn.isEmpty {
                    throw NSError.newError("ALPN 存在但为空")
                } else {
                    model.tls?.alpn = alpn.components(separatedBy: ",").compactMap(MGConfiguration.ALPN.init(rawValue:)).map(\.rawValue)
                }
            }
        case .reality:
            model.reality = MGConfiguration.StreamSettings.Reality()
            if let pbk = mapping["pbk"] {
                model.reality?.publicKey = pbk
            }
            if let sid = mapping["sid"] {
                model.reality?.shortId = sid
            }
            if let spx = mapping["spx"] {
                model.reality?.spiderX = spx
            }
            if let pbk = mapping["pbk"] {
                model.reality?.publicKey = pbk
            }
            if let sni = mapping["sni"] {
                if sni.isEmpty {
                    throw NSError.newError("SNI 存在但为空")
                } else {
                    model.reality?.serverName = sni
                }
            } else {
                model.reality?.serverName = host
            }
            model.reality?.fingerprint = mapping["fp"].flatMap(MGConfiguration.Fingerprint.init(rawValue:)) ?? .chrome
        }
        self.id = UUID()
        self.name = components.fragment ?? ""
        self.type = type
        self.model = model
    }
}

struct MGConfigurationListView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var packetTunnelManager: MGPacketTunnelManager
    @EnvironmentObject private var configurationListManager: MGConfigurationListManager
        
    @State private var isRenameAlertPresented = false
    @State private var configurationName: String = ""
    
    @State private var editModel: MGConfigurationEditModel?
    
    @State private var location: MGConfigurationLocation?
    
    @State private var isConfirmationDialogPresented = false
    @State private var protocolType: MGConfiguration.ProtocolType?
    
    @State private var isCodeScannerPresented: Bool = false
    @State private var scanResult: Swift.Result<ScanResult, ScanError>?
    
    let current: Binding<String>
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isConfirmationDialogPresented.toggle()
                    } label: {
                        Label("创建", systemImage: "square.and.pencil")
                    }
                    Button {
                        isCodeScannerPresented.toggle()
                    } label: {
                        Label("扫描二维码", systemImage: "qrcode.viewfinder")
                    }
                    .confirmationDialog("", isPresented: $isConfirmationDialogPresented) {
                        ForEach(MGConfiguration.ProtocolType.allCases) { value in
                            Button(value.description) {
                                protocolType = value
                            }
                        }
                    }
                    .fullScreenCover(item: $protocolType, onDismiss: { configurationListManager.reload() }) { protocolType in
                        MGCreateOrUpdateConfigurationView(
                            vm: MGCreateOrUpdateConfigurationViewModel(id: UUID(), descriptive: "", protocolType: protocolType, configurationModel: nil)
                        )
                    }
                } header: {
                    Text("创建配置")
                }
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
                    Text("导入自定义配置")
                } footer: {
                    Text("自定义配置入站只支持SOCKS5, 监听地址为[::1], 端口为\(MGNetworkModel.current.inboundPort)(可在设置中修改), 不支持用户名密码认证")
                }
                Section {
                    if configurationListManager.configurations.isEmpty {
                        NoConfigurationView()
                    } else {
                        ForEach(configurationListManager.configurations) { configuration in
                            ConfigurationItemView(configuration: configuration)
                                .listRowBackground(current.wrappedValue == configuration.id ? Color.accentColor : nil)
                        }
                    }
                } header: {
                    Text("配置列表")
                }
            }
            .navigationTitle(Text("配置管理"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $location) { location in
                MGConfigurationLoadView(location: location)
            }
            .fullScreenCover(item: $editModel, onDismiss: { configurationListManager.reload() }) { em in
                MGCreateOrUpdateConfigurationView(
                    vm: MGCreateOrUpdateConfigurationViewModel(id: em.id, descriptive: em.name, protocolType: em.type, configurationModel: em.model)
                )
            }
            .fullScreenCover(isPresented: $isCodeScannerPresented) {
                guard let res = self.scanResult else {
                    return
                }
                self.scanResult = nil
                self.handleScanResult(res)
            } content: {
                MGQRCodeScannerView(result: $scanResult)
            }
        }
    }
    
    private func handleScanResult(_ result: Swift.Result<ScanResult, ScanError>) {
        switch result {
        case .success(let success):
            do {
                self.editModel = try MGConfigurationEditModel(code: success.string)
            } catch {
                MGNotification.send(title: "", subtitle: "", body: error.localizedDescription)
            }
        case .failure(let failure):
            let message: String
            switch failure {
            case .badInput:
                message = "输入错误"
            case .badOutput:
                message = "输出错误"
            case .permissionDenied:
                message = "权限错误"
            case .initError(let error):
                message = error.localizedDescription
            }
            MGNotification.send(title: "", subtitle: "", body: message)
        }
    }
    
    @ViewBuilder
    private func ConfigurationItemView(configuration: MGConfiguration) -> some View {
        Button {
            guard current.wrappedValue != configuration.id else {
                return
            }
            current.wrappedValue = configuration.id
        } label: {
            HStack(alignment: .center, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(configuration.attributes.alias)
                        .foregroundColor(current.wrappedValue == configuration.id ? .white : .primary)
                        .fontWeight(.medium)
                    Text(configuration.typeString)
                        .foregroundColor(current.wrappedValue == configuration.id ? .white : .primary)
                        .font(.caption)
                        .fontWeight(.light)
                }
                Spacer()
                if configurationListManager.downloadingConfigurationIDs.contains(configuration.id) {
                    ProgressView()
                } else {
                    TimelineView(.periodic(from: Date(), by: 1)) { _ in
                        Text(configuration.attributes.leastUpdated.formatted(.relative(presentation: .numeric)))
                            .foregroundColor(current.wrappedValue == configuration.id ? .white : .primary)
                            .font(.callout)
                            .fontWeight(.light)
                    }
                }
            }
            .lineLimit(1)
        }
        .contextMenu {
            RenameOrEditButton(configuration: configuration)
            UpdateButton(configuration: configuration)
            Divider()
            DeleteButton(configuration: configuration)
        }
    }
    
    @ViewBuilder
    private func NoConfigurationView() -> some View {
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
    }
    
    @ViewBuilder
    private func RenameOrEditButton(configuration: MGConfiguration) -> some View {
        Button {
            if configuration.isUserCreated {
                do {
                    self.editModel = try MGConfigurationEditModel(configuration: configuration)
                } catch {
                    MGNotification.send(title: "", subtitle: "", body: "加载文件失败, 原因: \(error.localizedDescription)")
                }
            } else {
                self.configurationName = configuration.attributes.alias
                self.isRenameAlertPresented.toggle()
            }
        } label: {
            Label(configuration.isUserCreated ? "编辑" : "重命名", systemImage: "square.and.pencil")
        }
        .alert("重命名", isPresented: $isRenameAlertPresented) {
            TextField("请输入配置名称", text: $configurationName)
            Button("确定") {
                let name = configurationName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !(name == configuration.attributes.alias || name.isEmpty) else {
                    return
                }
                do {
                    try configurationListManager.rename(configuration: configuration, name: name)
                } catch {
                    MGNotification.send(title: "", subtitle: "", body: "重命名失败, 原因: \(error.localizedDescription)")
                }
            }
            Button("取消", role: .cancel) {}
        }
    }
    
    @ViewBuilder
    private func UpdateButton(configuration: MGConfiguration) -> some View {
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
        .disabled(configurationListManager.downloadingConfigurationIDs.contains(configuration.id) || configuration.isLocal)
    }
    
    @ViewBuilder
    private func DeleteButton(configuration: MGConfiguration) -> some View {
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


struct MGQRCodeScannerView: View {
        
    @Environment(\.dismiss) private var dismiss
    
    let result: Binding<Swift.Result<ScanResult, ScanError>?>
    
    var body: some View {
        NavigationStack {
            CodeScannerView(codeTypes: [.qr]) {
                result.wrappedValue = $0
                dismiss()
            }
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}
