import Foundation

extension MGConstant {
    public static let route: String = "XRAY_ROUTE_DATA"
}

public struct MGRouteModel: Codable, Equatable {
    
    public let usingPredefinedRoute: Bool
    public let domainStrategy: MGConfiguration.RouteDomainStrategy
    public let predefinedRule: MGConfiguration.RoutePredefineRule
    public let customizeRoute: String
    
    public static let `default` = MGRouteModel(
        usingPredefinedRoute: true,
        domainStrategy: .asIs,
        predefinedRule: .rule,
        customizeRoute: "{}"
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
