import Foundation

final class MGRouteViewModel: ObservableObject {
    
    @Published var usingPredefinedRoute: Bool
    @Published var domainStrategy: MGConfiguration.RouteDomainStrategy
    @Published var predefinedRule: MGConfiguration.RoutePredefineRule
    @Published var customizeRoute: String
        
    private var current: MGRouteModel
    
    init() {
        let model                   = MGRouteModel.current
        self.usingPredefinedRoute   = model.usingPredefinedRoute
        self.domainStrategy         = model.domainStrategy
        self.predefinedRule         = model.predefinedRule
        self.customizeRoute         = model.customizeRoute
        self.current = model
    }
    
    static func setupDefaultSettingsIfNeeded() {
        guard UserDefaults.shared.data(forKey: MGConstant.sniffing) == nil else {
            return
        }
        do {
            UserDefaults.shared.set(try JSONEncoder().encode(MGSniffingModel.default), forKey: MGConstant.sniffing)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func save(updated: () -> Void) {
        do {
            let model = MGRouteModel(
                usingPredefinedRoute: self.usingPredefinedRoute,
                domainStrategy: self.domainStrategy,
                predefinedRule: self.predefinedRule,
                customizeRoute: self.customizeRoute
            )
            guard model != self.current else {
                return
            }
            UserDefaults.shared.set(try JSONEncoder().encode(model), forKey: MGConstant.sniffing)
            self.current = model
            updated()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
