import NetworkExtension
import XrayKit
import Tun2SocksKit
import os

class PacketTunnelProvider: NEPacketTunnelProvider, XrayLoggerProtocol {
    
    private let logger = Logger(subsystem: "com.Arror.Mango.XrayTunnel", category: "Core")
    
    override func startTunnel(options: [String : NSObject]? = nil) async throws {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "254.1.1.1")
        settings.mtu = 9000
        let netowrk = MGNetworkModel.current
        settings.ipv4Settings = {
            let settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
            settings.includedRoutes = [NEIPv4Route.default()]
            if netowrk.hideVPNIcon {
                settings.excludedRoutes = [NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "255.0.0.0")]
            }
            return settings
        }()
        settings.ipv6Settings = {
            guard netowrk.ipv6Enabled else {
                return nil
            }
            let settings = NEIPv6Settings(addresses: ["fd6e:a81b:704f:1211::1"], networkPrefixLengths: [64])
            settings.includedRoutes = [NEIPv6Route.default()]
            if netowrk.hideVPNIcon {
                settings.excludedRoutes = [NEIPv6Route(destinationAddress: "::", networkPrefixLength: 64)]
            }
            return settings
        }()
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "114.114.114.114"])
        try await self.setTunnelNetworkSettings(settings)
        do {
            guard let id = UserDefaults.shared.string(forKey: MGConfiguration.currentStoreKey), !id.isEmpty else {
                fatalError()
            }
            let folderURL = MGConstant.configDirectory.appending(component: id)
            let folderAttributes = try FileManager.default.attributesOfItem(atPath: folderURL.path(percentEncoded: false))
            guard let mapping = folderAttributes[MGConfiguration.key] as? [String: Data],
                  let data = mapping[MGConfiguration.Attributes.key] else {
                fatalError()
            }
            let attributes = try JSONDecoder().decode(MGConfiguration.Attributes.self, from: data)
            let fileURL = folderURL.appending(component: "config.\(attributes.format.rawValue)")
            let filePath: String
            let port: Int
            if let protocolType = attributes.source.scheme.flatMap(MGConfiguration.ProtocolType.init(rawValue:)) {
                port = XrayGetAvailablePort()
                let data = try generateConfiguration(
                    port: port,
                    protocolType: protocolType,
                    configurationModel: try JSONDecoder().decode(MGConfigurationModel.self, from: try Data(contentsOf: fileURL))
                )
                let cache = URL(filePath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0], directoryHint: .isDirectory)
                NSLog(String(data: data, encoding: .utf8) ?? "")
                filePath = cache.appending(component: "\(UUID().uuidString).json", directoryHint: .notDirectory).path(percentEncoded: false)
                FileManager.default.createFile(atPath: filePath, contents: data)
            } else {
                port = 10864
                filePath = fileURL.path(percentEncoded: false)
            }
            let log = MGLogModel.current
            XraySetLogger(self)
            XraySetAccessLogEnable(log.accessLogEnabled)
            XraySetDNSLogEnable(log.dnsLogEnabled)
            XraySetErrorLogSeverity(log.errorLogSeverity.rawValue)
            XraySetAsset(MGConstant.assetDirectory.path(percentEncoded: false), nil)
            var error: NSError? = nil
            XrayRun(filePath, &error)
            try error.flatMap { throw $0 }
            let config = """
            tunnel:
              mtu: 9000
            socks5:
              port: \(port)
              address: ::1
              udp: 'udp'
            misc:
              task-stack-size: 20480
              connect-timeout: 5000
              read-write-timeout: 60000
              log-file: stderr
              log-level: error
              limit-nofile: 65535
            """
            let cache = URL(filePath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0], directoryHint: .isDirectory)
            let file = cache.appending(component: "\(UUID().uuidString).yml", directoryHint: .notDirectory)
            try config.write(to: file, atomically: true, encoding: .utf8)
            DispatchQueue.global(qos: .userInitiated).async {
                NSLog("HEV_SOCKS5_TUNNEL_MAIN: \(Socks5Tunnel.run(withConfig: file.path(percentEncoded: false)))")
            }
        } catch {
            MGNotification.send(title: "", subtitle: "", body: error.localizedDescription)
            throw error
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason) async {
        let message: String
        switch reason {
        case .none:
            message = "No specific reason."
        case .userInitiated:
            message = "The user stopped the provider."
        case .providerFailed:
            message = "The provider failed."
        case .noNetworkAvailable:
            message = "There is no network connectivity."
        case .unrecoverableNetworkChange:
            message = "The device attached to a new network."
        case .providerDisabled:
            message = "The provider was disabled."
        case .authenticationCanceled:
            message = "The authentication process was cancelled."
        case .configurationFailed:
            message = "The provider could not be configured."
        case .idleTimeout:
            message = "The provider was idle for too long."
        case .configurationDisabled:
            message = "The associated configuration was disabled."
        case .configurationRemoved:
            message = "The associated configuration was deleted."
        case .superceded:
            message = "A high-priority configuration was started."
        case .userLogout:
            message = "The user logged out."
        case .userSwitch:
            message = "The active user changed."
        case .connectionFailed:
            message = "Failed to establish connection."
        case .sleep:
            message = "The device went to sleep and disconnectOnSleep is enabled in the configuration."
        case .appUpdate:
            message = "The NEProvider is being updated."
        @unknown default:
            return
        }
        MGNotification.send(title: "", subtitle: "", body: message)
    }
    
    func onAccessLog(_ message: String?) {
        message.flatMap { logger.log("\($0, privacy: .public)") }
    }
    
    func onDNSLog(_ message: String?) {
        message.flatMap { logger.log("\($0, privacy: .public)") }
    }
    
    func onGeneralMessage(_ severity: Int, message: String?) {
        let level = MGLogModel.Severity(rawValue: severity) ?? .none
        guard let message = message, !message.isEmpty else {
            return
        }
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .none:
            break
        }
    }
    
    private func generateConfiguration(port: Int, protocolType: MGConfiguration.ProtocolType, configurationModel: MGConfigurationModel) throws -> Data {
        var mapping: [String: Any] = [:]
        mapping["inbounds"] = {
            var mapping: [String: Any] = [:]
            mapping["listen"] = "[::1]"
            mapping["protocol"] = "socks"
            mapping["settings"] = {
                var mapping: [String: Any] = [:]
                mapping["udp"] = true
                mapping["auth"] = "noauth"
                return mapping
            }()
            mapping["tag"] = "socks-in"
            mapping["port"] = port
            mapping["sniffing"] = {
                let sniffing = MGSniffingModel.current
                var mapping: [String: Any] = [:]
                mapping["enabled"] = sniffing.enabled
                mapping["destOverride"] = {
                    var temp: [String] = []
                    if sniffing.httpEnabled {
                        temp.append("http")
                    }
                    if sniffing.tlsEnabled {
                        temp.append("tls")
                    }
                    if sniffing.quicEnabled {
                        temp.append("quic")
                    }
                    if sniffing.fakednsEnabled {
                        temp.append("fakedns")
                    }
                    if temp.count == 4 {
                        temp = ["fakedns+others"]
                    }
                    return temp
                }()
                mapping["metadataOnly"] = sniffing.metadataOnly
                mapping["domainsExcluded"] = sniffing.excludedDomains
                mapping["routeOnly"] = sniffing.routeOnly
                return mapping
            }()
            return [mapping]
        }()
        mapping["outbounds"] = {
            var mapping: [String: Any] = [:]
            mapping["tag"] = "proxy"
            mapping["settings"] = {
                switch protocolType {
                case .vless:
                    return configurationModel.vless?.toJSON()
                case .vmess:
                    return configurationModel.vmess?.toJSON()
                case .trojan:
                    return configurationModel.trojan?.toJSON()
                case .shadowsocks:
                    return configurationModel.shadowsocks?.toJSON()
                }
            }()
            mapping["streamSettings"] = {
                var mapping: [String: Any] = [:]
                mapping["network"] = configurationModel.network.rawValue
                switch configurationModel.network {
                case .tcp:
                    mapping["tcpSettings"] = configurationModel.tcp?.toJSON()
                case .kcp:
                    mapping["kcpSettings"] = configurationModel.kcp?.toJSON()
                case .ws:
                    mapping["wsSettings"] = configurationModel.ws?.toJSON()
                case .http:
                    mapping["httpSettings"] = configurationModel.http?.toJSON()
                case .quic:
                    mapping["quicSettings"] = configurationModel.quic?.toJSON()
                case .grpc:
                    mapping["grpcSettings"] = configurationModel.grpc?.toJSON()
                }
                mapping["security"] = configurationModel.security.rawValue
                switch configurationModel.security {
                case .none:
                    break
                case .tls:
                    mapping["tlsSettings"] = configurationModel.tls?.toJSON()
                case .reality:
                    mapping["realitySettings"] = configurationModel.reality?.toJSON()
                }
                return mapping
            }()
            return [mapping]
        }()
        return try JSONSerialization.data(withJSONObject: mapping, options: .prettyPrinted)
    }
}

extension Encodable {
    func toJSON() -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: try JSONEncoder().encode(self))
        } catch {
            return nil
        }
    }
}
