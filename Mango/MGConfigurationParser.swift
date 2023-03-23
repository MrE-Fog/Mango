import Foundation

struct MGConfigurationComponents {
    
    let protocolType: MGConfiguration.ProtocolType
    let user: String
    let host: String
    let port: Int
    let queryMapping: [String: String]
    let network: MGConfiguration.Transport
    let security: MGConfiguration.Security
    let descriptive: String
    
    init(urlString: String) throws {
        guard let components = URLComponents(string: urlString),
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

protocol MGConfigurationParserProtocol {
    
    associatedtype Output
    
    func parse(with components: MGConfigurationComponents) throws -> Optional<Output>
}

extension MGConfiguration.VLESS: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.VMess: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.Trojan: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.Shadowsocks: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.TCP: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.KCP: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.WS: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.HTTP: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.QUIC: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.GRPC: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.TLS: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}

extension MGConfiguration.StreamSettings.Reality: MGConfigurationParserProtocol {
        
    func parse(with components: MGConfigurationComponents) throws -> Optional<Self> {
        return .none
    }
}
