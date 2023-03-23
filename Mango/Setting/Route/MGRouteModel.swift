import Foundation

extension MGConstant {
    public static let route: String = "XRAY_ROUTE_DATA"
}

public struct MGRouteModel: Codable, Equatable {
    
    public let usingPredefinedRule: Bool
    public let domainStrategy: MGConfiguration.RouteDomainStrategy
    public let predefinedRule: MGConfiguration.RoutePredefinedRule
    public let customizedRule: String
    
    public static let `default` = MGRouteModel(
        usingPredefinedRule: true,
        domainStrategy: .asIs,
        predefinedRule: .rule,
        customizedRule: "[]"
    )
    
    public static var current: MGRouteModel {
        do {
            guard let data = UserDefaults.shared.data(forKey: MGConstant.sniffing) else {
                return .default
            }
            return try JSONDecoder().decode(MGRouteModel.self, from: data)
        } catch {
            return .default
        }
    }
}
