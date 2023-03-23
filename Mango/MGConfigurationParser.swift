import Foundation

extension MGConfiguration {
    
    struct URLComponents {
        
        let protocolType: MGConfiguration.ProtocolType
        let user: String
        let host: String
        let port: Int
        let queryMapping: [String: String]
        let network: MGConfiguration.Transport
        let security: MGConfiguration.Security
        let descriptive: String
        
        init(urlString: String) throws {
            guard let components = Foundation.URLComponents(string: urlString),
                  let protocolType = components.scheme.flatMap(MGConfiguration.ProtocolType.init(rawValue:)) else {
                throw NSError.newError("协议链接解析失败")
            }
            guard protocolType == .trojan || protocolType == .shadowsocks else {
                throw NSError.newError("暂不支持\(protocolType.description)协议解析")
            }
            guard let user = components.user, !user.isEmpty else {
                throw NSError.newError("用户不存在")
            }
            guard let host = components.host, !host.isEmpty else {
                throw NSError.newError("服务器域名或地址不存在")
            }
            guard let port = components.port, (1...65535).contains(port) else {
                throw NSError.newError("服务器的端口号不合法")
            }
            let mapping = (components.queryItems ?? []).reduce(into: [String: String](), { result, item in
                result[item.name] = item.value
            })
            let network: MGConfiguration.Transport
            if let value = mapping["type"], !value.isEmpty {
                if let value = MGConfiguration.Transport(rawValue: value) {
                    network = value
                } else {
                    throw NSError.newError("未知的传输方式")
                }
            } else {
                throw NSError.newError("传输方式不能为空")
            }
            let security: MGConfiguration.Security
            if let value = mapping["security"] {
                if value.isEmpty {
                    throw NSError.newError("传输安全不能为空")
                } else {
                    if let value = MGConfiguration.Security(rawValue: value) {
                        security = value
                    } else {
                        throw NSError.newError("未知的传输安全方式")
                    }
                }
            } else {
                security = .none
            }
            self.protocolType = protocolType
            self.user = user
            self.host = host
            self.port = port
            self.network = network
            self.security = security
            self.queryMapping = mapping
            self.descriptive = components.fragment ?? ""
        }
    }
}


protocol MGConfigurationParserProtocol {
    
    associatedtype Output
    
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Output>
}

extension MGConfiguration.VLESS: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.VMess: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.Trojan: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.Shadowsocks: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.TCP: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.KCP: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.WS: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.HTTP: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.QUIC: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.GRPC: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.TLS: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.Reality: MGConfigurationParserProtocol {
        
    static func parse(with components: MGConfiguration.URLComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.Model {
    
    init(components: MGConfiguration.URLComponents) throws {
        self.vless          = try MGConfiguration.VLESS.parse(with: components)
        self.vmess          = try MGConfiguration.VMess.parse(with: components)
        self.trojan         = try MGConfiguration.Trojan.parse(with: components)
        self.shadowsocks    = try MGConfiguration.Shadowsocks.parse(with: components)
        self.network        = components.network
        self.tcp            = try MGConfiguration.StreamSettings.TCP.parse(with: components)
        self.kcp            = try MGConfiguration.StreamSettings.KCP.parse(with: components)
        self.ws             = try MGConfiguration.StreamSettings.WS.parse(with: components)
        self.http           = try MGConfiguration.StreamSettings.HTTP.parse(with: components)
        self.quic           = try MGConfiguration.StreamSettings.QUIC.parse(with: components)
        self.grpc           = try MGConfiguration.StreamSettings.GRPC.parse(with: components)
        self.security       = components.security
        self.tls            = try MGConfiguration.StreamSettings.TLS.parse(with: components)
        self.reality        = try MGConfiguration.StreamSettings.Reality.parse(with: components)
    }
}

/*
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
*/
