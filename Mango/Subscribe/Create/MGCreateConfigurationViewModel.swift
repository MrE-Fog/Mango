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
    
    init(protocolType: MGConfiguration.ProtocolType, protocolModel: MGProtocolModel? = nil) {
        self.protocolType = protocolType
        self.isEditMode = protocolModel != nil
    }
    
    func save() throws {
        let id = UUID()
        let folderURL = MGConstant.configDirectory.appending(component: "\(id.uuidString)")
        let attributes = MGConfiguration.Attributes(
            alias: descriptive.trimmingCharacters(in: .whitespacesAndNewlines),
            source: URL(string: "\(protocolType.rawValue)://")!,
            leastUpdated: Date(),
            format: .json
        )
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true,
            attributes: [
                MGConfiguration.key: [MGConfiguration.Attributes.key: try JSONEncoder().encode(attributes)]
            ]
        )
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
