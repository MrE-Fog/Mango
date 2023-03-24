import NetworkExtension
import XrayKit
import Tun2SocksKit
import os

extension MGConstant {
    static let cachesDirectory = URL(filePath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])
}

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
                settings.excludedRoutes = [NEIPv6Route(destinationAddress: "::", networkPrefixLength: 128)]
            }
            return settings
        }()
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "114.114.114.114"])
        try await self.setTunnelNetworkSettings(settings)
        do {
            try self.startXray(inboundPort: netowrk.inboundPort)
            try self.startSocks5Tunnel(serverPort: netowrk.inboundPort)
        } catch {
            MGNotification.send(title: "", subtitle: "", body: error.localizedDescription)
            throw error
        }
    }
    
    private func startXray(inboundPort: Int) throws {
        guard let id = UserDefaults.shared.string(forKey: MGConfiguration.currentStoreKey), !id.isEmpty else {
            throw NSError.newError("当前无有效配置")
        }
        let configuration = try MGConfiguration(uuidString: id)
        let data = try configuration.loadData(inboundPort: inboundPort)
        let configurationFilePath = MGConstant.cachesDirectory.appending(component: "config.json").path(percentEncoded: false)
        guard FileManager.default.createFile(atPath: configurationFilePath, contents: data) else {
            throw NSError.newError("Xray 配置文件写入失败")
        }
        let log = MGLogModel.current
        XraySetupLogger(self, log.accessLogEnabled, log.dnsLogEnabled, log.errorLogSeverity.rawValue)
        XraySetenv("XRAY_LOCATION_CONFIG", MGConstant.cachesDirectory.path(percentEncoded: false), nil)
        XraySetenv("XRAY_LOCATION_ASSET", MGConstant.assetDirectory.path(percentEncoded: false), nil)
        var error: NSError? = nil
        XrayRun(&error)
        try error.flatMap { throw $0 }
    }
    
    private func startSocks5Tunnel(serverPort port: Int) throws {
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
        let configurationFilePath = MGConstant.cachesDirectory.appending(component: "config.yml").path(percentEncoded: false)
        guard FileManager.default.createFile(atPath: configurationFilePath, contents: config.data(using: .utf8)!) else {
            throw NSError.newError("Tunnel 配置文件写入失败")
        }
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("HEV_SOCKS5_TUNNEL_MAIN: \(Socks5Tunnel.run(withConfig: configurationFilePath))")
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
}

extension MGConfiguration {
    
    func loadData(inboundPort: Int) throws -> Data {
        let file = MGConstant.configDirectory.appending(component: "\(self.id)/config.json")
        let data = try Data(contentsOf: file)
        if let protocolType = self.attributes.source.scheme.flatMap(MGConfiguration.ProtocolType.init(rawValue:)) {
            let model = try JSONDecoder().decode(MGConfiguration.Model.self, from: data)
            return try model.buildConfigurationData(of: protocolType, inboundPort: inboundPort)
        } else {
            return data
        }
    }
}

extension MGConfiguration.Model {
    
    func buildConfigurationData(of protocolType: MGConfiguration.ProtocolType, inboundPort: Int) throws -> Data {
        var configuration: [String: Any] = [:]
        configuration["inbounds"] = {
            var inbound: [String: Any] = [:]
            inbound["listen"] = "[::1]"
            inbound["protocol"] = "socks"
            inbound["settings"] = {
                var settings: [String: Any] = [:]
                settings["udp"] = true
                settings["auth"] = "noauth"
                return settings
            }()
            inbound["tag"] = "socks-in"
            inbound["port"] = inboundPort
            inbound["sniffing"] = {
                let current = MGSniffingModel.current
                var sniffing: [String: Any] = [:]
                sniffing["enabled"] = current.enabled
                sniffing["destOverride"] = {
                    var destOverride: [String] = []
                    if current.httpEnabled {
                        destOverride.append("http")
                    }
                    if current.tlsEnabled {
                        destOverride.append("tls")
                    }
                    if current.quicEnabled {
                        destOverride.append("quic")
                    }
                    if current.fakednsEnabled {
                        destOverride.append("fakedns")
                    }
                    if destOverride.count == 4 {
                        destOverride = ["fakedns+others"]
                    }
                    return destOverride
                }()
                sniffing["metadataOnly"] = current.metadataOnly
                sniffing["domainsExcluded"] = current.excludedDomains
                sniffing["routeOnly"] = current.routeOnly
                return sniffing
            }()
            return [inbound]
        }()
        configuration["routing"] = {
            let model = MGRouteModel.current
            var routing: [String: Any] = [:]
            routing["domainStrategy"] = model.domainStrategy.rawValue
            if model.usingPredefinedRule {
                routing["rules"] = {
                    let geosite_category_ads_all: [String: Any] = [
                        "type": "field",
                        "domain": ["geosite:category-ads-all"],
                        "outboundTag": "block"
                    ]
                    let geosite_games_cn: [String: Any] = [
                        "type": "field",
                        "domain": ["geosite:category-games@cn"],
                        "outboundTag": "direct"
                    ]
                    let geosite_geolocation_not_cn: [String: Any] = [
                        "type": "field",
                        "domain": ["geosite:geolocation-!cn"],
                        "outboundTag": "proxy"
                    ]
                    let geosite_cn_private: [String: Any] = [
                        "type": "field",
                        "domain": ["geosite:cn", "geosite:private"],
                        "outboundTag": "direct"
                    ]
                    let geoip_cn_private: [String: Any] = [
                        "type": "field",
                        "ip": ["geoip:cn", "geoip:private"],
                        "outboundTag": "direct"
                    ]
                    return [geosite_category_ads_all, geosite_games_cn, geosite_geolocation_not_cn, geosite_cn_private, geoip_cn_private]
                }()
            } else {
                do {
                    guard let data = model.customizedRule.data(using: .utf8) else {
                        throw NSError.newError("")
                    }
                    guard let rules = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                        throw NSError.newError("")
                    }
                    return rules
                } catch {
                    return []
                }
            }
            return routing
        }()
        configuration["outbounds"] = {
            var proxy: [String: Any] = [:]
            proxy["tag"] = "proxy"
            proxy["protocol"] = protocolType.rawValue
            proxy["settings"] = {
                switch protocolType {
                case .vless:
                    guard let vless = self.vless?.toJSON() else {
                        return nil
                    }
                    return ["vnext": [vless]]
                case .vmess:
                    guard let vmess = self.vmess?.toJSON() else {
                        return nil
                    }
                    return ["vnext": [vmess]]
                case .trojan:
                    guard let trojan = self.trojan?.toJSON() else {
                        return nil
                    }
                    return ["servers": [trojan]]
                case .shadowsocks:
                    guard let shadowsocks = self.shadowsocks?.toJSON() else {
                        return nil
                    }
                    return ["servers": [shadowsocks]]
                }
            }()
            proxy["streamSettings"] = {
                var network: [String: Any] = [:]
                network["network"] = self.network.rawValue
                switch self.network {
                case .tcp:
                    network["tcpSettings"] = self.tcp?.toJSON()
                case .kcp:
                    network["kcpSettings"] = self.kcp?.toJSON()
                case .ws:
                    network["wsSettings"] = self.ws?.toJSON()
                case .http:
                    network["httpSettings"] = self.http?.toJSON()
                case .quic:
                    network["quicSettings"] = self.quic?.toJSON()
                case .grpc:
                    network["grpcSettings"] = self.grpc?.toJSON()
                }
                network["security"] = self.security.rawValue
                switch self.security {
                case .none:
                    break
                case .tls:
                    network["tlsSettings"] = self.tls?.toJSON()
                case .reality:
                    network["realitySettings"] = self.reality?.toJSON()
                }
                return network
            }()
            
            let direct: [String: String] = [
                "tag": "direct",
                "protocol": "freedom"
            ]
            
            let block: [String: Any] = [
                "tag": "block",
                "protocol": "blackhole"
            ]
            
            return [proxy, direct, block]
        }()
        return try JSONSerialization.data(withJSONObject: configuration, options: .prettyPrinted)
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
