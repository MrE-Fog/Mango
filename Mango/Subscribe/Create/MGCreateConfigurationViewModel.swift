import Foundation

final class MGCreateConfigurationViewModel: ObservableObject {
    
    @Published var vless        = MGConfiguration.VLESS()
    @Published var vmess        = MGConfiguration.VMess()
    @Published var trojan       = MGConfiguration.Trojan()
    @Published var shadowsocks  = MGConfiguration.Shadowsocks()
    
    @Published var network  = MGConfiguration.Network.tcp
    @Published var tcp      = MGConfiguration.StreamSettings.TCP()
    @Published var kcp      = MGConfiguration.StreamSettings.KCP()
    @Published var ws       = MGConfiguration.StreamSettings.WS()
    @Published var http     = MGConfiguration.StreamSettings.HTTP()
    @Published var quic     = MGConfiguration.StreamSettings.QUIC()
    @Published var grpc     = MGConfiguration.StreamSettings.GRPC()
    
    @Published var security = MGConfiguration.Security.none
    @Published var tls      = MGConfiguration.StreamSettings.TLS()
    @Published var reality  = MGConfiguration.StreamSettings.Reality()
        
    @Published var descriptive: String = ""
    
    let protocolType: MGConfiguration.ProtocolType
    let isEditMode: Bool
    
    let id: UUID
    
    init(id: UUID, protocolType: MGConfiguration.ProtocolType, descriptive: String = "", protocolModel: MGProtocolModel? = nil) {
        self.id = id
        self.protocolType = protocolType
        self.descriptive = descriptive
        guard let protocolModel = protocolModel else {
            self.isEditMode = false
            return
        }
        self.isEditMode = true
        func updateNetwork(model: MGTransportModel) {
            switch model {
            case .tcp(let tcp):
                self.network = .tcp
                self.tcp = tcp
            case .kcp(let kcp):
                self.network = .kcp
                self.kcp = kcp
            case .ws(let ws):
                self.network = .ws
                self.ws = ws
            case .http(let http):
                self.network = .http
                self.http = http
            case .quic(let quic):
                self.network = .quic
                self.quic = quic
            case .grpc(let grpc):
                self.network = .grpc
                self.grpc = grpc
            }
        }
        func updateSecurity(model: MGSecurityModel) {
            switch model {
            case .none:
                self.security = .none
            case .tls(let tls):
                self.security = .tls
                self.tls = tls
            case .reality(let reality):
                self.security = .reality
                self.reality = reality
            }
        }
        switch protocolModel {
        case .vless(let vless, let network, let security):
            self.vless = vless
            updateNetwork(model: network)
            updateSecurity(model: security)
        case .vmess(let vmess, let network, let security):
            self.vmess = vmess
            updateNetwork(model: network)
            updateSecurity(model: security)
        case .trojan(let trojan, let network, let security):
            self.trojan = trojan
            updateNetwork(model: network)
            updateSecurity(model: security)
        case .shadowsocks(let shadowsocks):
            self.shadowsocks = shadowsocks
        }
    }
    
    func save() throws {
        let folderURL = MGConstant.configDirectory.appending(component: "\(self.id.uuidString)")
        let attributes = MGConfiguration.Attributes(
            alias: descriptive.trimmingCharacters(in: .whitespacesAndNewlines),
            source: URL(string: "\(protocolType.rawValue)://")!,
            leastUpdated: Date(),
            format: .json
        )
        if isEditMode {
            try FileManager.default.setAttributes([
                MGConfiguration.key: [MGConfiguration.Attributes.key: try JSONEncoder().encode(attributes)]
            ], ofItemAtPath: folderURL.path(percentEncoded: false))
        } else {
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true,
                attributes: [
                    MGConfiguration.key: [MGConfiguration.Attributes.key: try JSONEncoder().encode(attributes)]
                ]
            )
        }
        let destinationURL = folderURL.appending(component: "config.\(MGConfigurationFormat.json.rawValue)")
        let data = try JSONEncoder().encode(self.createProtocolModel())
        FileManager.default.createFile(atPath: destinationURL.path(percentEncoded: false), contents: data)
    }
    
    private func createProtocolModel() -> MGProtocolModel {
        switch self.protocolType {
        case .vless:
            return .vless(vless, createTransportModel(), createSecurityModel())
        case .vmess:
            return .vmess(vmess, createTransportModel(), createSecurityModel())
        case .trojan:
            return .trojan(trojan, createTransportModel(), createSecurityModel())
        case .shadowsocks:
            return .shadowsocks(shadowsocks)
        }
    }
    
    private func createTransportModel() -> MGTransportModel {
        switch self.network {
        case .tcp:
            return .tcp(tcp)
        case .kcp:
            return .kcp(kcp)
        case .ws:
            return .ws(ws)
        case .http:
            return .http(http)
        case .quic:
            return .quic(quic)
        case .grpc:
            return .grpc(grpc)
        }
    }
    
    private func createSecurityModel() -> MGSecurityModel {
        switch self.security {
        case .none:
            return .none
        case .tls:
            return .tls(tls)
        case .reality:
            return .reality(reality)
        }
    }
}
