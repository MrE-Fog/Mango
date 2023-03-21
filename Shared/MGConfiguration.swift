import Foundation

public struct MGConfiguration: Identifiable {
    
    public static let currentStoreKey = "XRAY_CURRENT"
    
    public static let key = FileAttributeKey("NSFileExtendedAttributes")
    
    public let id: String
    public let creationDate: Date
    public let attributes: Attributes
}

extension MGConfiguration {
    
    public struct Attributes: Codable {
        
        public static let key = "Configuration.Attributes"
        
        public let alias: String
        public let source: URL
        public let leastUpdated: Date
        public let format: MGConfigurationFormat
    }
}

extension MGConfiguration {
    
    public enum ProtocolType: String, Identifiable, CaseIterable, CustomStringConvertible, Codable {
        
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
    
    public enum Network: String, Identifiable, CaseIterable, CustomStringConvertible, Codable {
        
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
    
    public enum Encryption: String, Identifiable, CustomStringConvertible, Codable {
        
        public var id: Self { self }
        
        case aes_128_gcm        = "aes-128-gcm"
        case chacha20_poly1305  = "chacha20-poly1305"
        case auto               = "auto"
        case none               = "none"
        case zero               = "zero"
        
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
        
        public static let vless: [MGConfiguration.Encryption] = [.auto, .aes_128_gcm, .chacha20_poly1305, .none]
        
        public static let vmess: [MGConfiguration.Encryption] = [.auto, .aes_128_gcm, .chacha20_poly1305, .none, .zero]
        
        public static let quic:  [MGConfiguration.Encryption] = [.none, .aes_128_gcm, .chacha20_poly1305]
    }
    
    public enum Security: String, Identifiable, CaseIterable, CustomStringConvertible, Codable {
        
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
    
    public enum HeaderType: String, Identifiable, CaseIterable, CustomStringConvertible, Codable {
        
        public var id: Self { self }
        
        case none           = "none"
        case srtp           = "srtp"
        case utp            = "utp"
        case wechat_video   = "wechat-video"
        case dtls           = "dtls"
        case wireguard      = "wireguard"
            
        public var description: String {
            switch self {
            case .none:
                return "None"
            case .srtp:
                return "SRTP"
            case .utp:
                return "UTP"
            case .wechat_video:
                return "Wecaht Video"
            case .dtls:
                return "DTLS"
            case .wireguard:
                return "Wireguard"
            }
        }
    }
    
    public enum Flow: String, Identifiable, CaseIterable, CustomStringConvertible, Codable {
        
        public var id: Self { self }
        
        case none                       = "none"
        case xtls_rprx_vision           = "xtls-rprx-vision"
        case xtls_rprx_vision_udp443    = "xtls-rprx-vision-udp443"
        
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
    
    public enum Fingerprint: String, Identifiable, CaseIterable, CustomStringConvertible, Codable {
        
        public var id: Self { self }
        
        case chrome     = "chrome"
        case firefox    = "firefox"
        case safari     = "safari"
        case ios        = "ios"
        case android    = "android"
        case edge       = "edge"
        case _360       = "360"
        case qq         = "qq"
        case random     = "random"
        case randomized = "randomized"
        
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
    
    public enum ALPN: String, Identifiable, CaseIterable, CustomStringConvertible, Codable {
        
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
    
    public struct StreamSettings: Codable {
        public struct TLS: Codable {
            public var serverName: String = ""
            public var rejectUnknownSni: Bool = false
            public var allowInsecure: Bool = false
            public var alpn: [String] = ["h2", "http/1.1"]
            public var minVersion: String = "1.2"
            public var maxVersion: String = "1.3"
            public var cipherSuites: String = ""
            public var certificates: [String] = []
            public var disableSystemRoot: Bool = false
            public var enableSessionResumption: Bool = false
            public var fingerprint: Fingerprint = .chrome
            public var pinnedPeerCertificateChainSha256: [String] = []
        }
        public struct Reality: Codable {
            public var show: Bool = false
            public var fingerprint: Fingerprint = .chrome
            public var serverName: String = ""
            public var publicKey: String = ""
            public var shortId: String = ""
            public var spiderX: String = ""
        }
        public struct TCP: Codable {
            public struct Header: Codable {
                public var type: HeaderType = .none
            }
            public var header = Header()
        }
        public struct KCP: Codable {
            public struct Header: Codable {
                public var type: HeaderType = .none
            }
            public var mtu: Int = 1350
            public var tti: Int = 20
            public var uplinkCapacity: Int = 5
            public var downlinkCapacity: Int = 20
            public var congestion: Bool = false
            public var readBufferSize: Int = 1
            public var writeBufferSize: Int = 1
            public var header = Header()
            public var seed: String = ""
        }
        public struct WS: Codable {
            public var path: String = "/"
            public var headers: [String: String] = [:]
            public var _host: String = "" {
                didSet {
                    if self._host.isEmpty {
                        self.headers = [:]
                    } else {
                        self.headers = ["Host": self._host]
                    }
                }
            }
        }
        public struct HTTP: Codable {
            public var host: [String] = []
            public var path: String = "/"
            public var read_idle_timeout: Int = 10
            public var health_check_timeout: Int = 15
            public var method: String = "PUT"
            public var headers: [String: [String]] = [:]
            public var _host: String = "" {
                didSet {
                    if self._host.isEmpty {
                        self.host = []
                    } else {
                        self.host = [self._host]
                    }
                }
            }
        }
        public struct QUIC: Codable {
            public struct Header: Codable {
                public var type: HeaderType = .none
            }
            public var security = Encryption.none
            public var key: String = ""
            public var header = Header()
        }
        public struct GRPC: Codable {
            public var serviceName: String = ""
            public var multiMode: Bool = false
            public var idle_timeout: Int = 60
            public var health_check_timeout: Int = 20
            public var permit_without_stream: Bool = false
            public var initial_windows_size: Int = 0
        }
        public var network          = Network.tcp
        public var security         = Security.none
        public var tlsSettings      = TLS()
        public var realitySettings  = Reality()
        public var tcpSettings      = TCP()
        public var kcpSettings      = KCP()
        public var wsSettings       = WS()
        public var httpSettings     = HTTP()
        public var quicSettings     = QUIC()
        public var grpcSettings     = GRPC()
    }
    
    public struct Mux: Codable {
        public var enabled: Bool = false
        public var concurrency: Int = 8
    }
}
