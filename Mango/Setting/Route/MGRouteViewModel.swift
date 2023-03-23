import Foundation

final class MGRouteViewModel: ObservableObject {
    
    @Published var usingPredefinedRule: Bool
    @Published var domainStrategy: MGConfiguration.RouteDomainStrategy
    @Published var predefinedRule: MGConfiguration.RoutePredefinedRule
    @Published var customizedRule: String
        
    private var current: MGRouteModel
    
    init() {
        let model                   = MGRouteModel.current
        self.usingPredefinedRule    = model.usingPredefinedRule
        self.domainStrategy         = model.domainStrategy
        self.predefinedRule         = model.predefinedRule
        self.customizedRule         = model.customizedRule
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
                usingPredefinedRule: self.usingPredefinedRule,
                domainStrategy: self.domainStrategy,
                predefinedRule: self.predefinedRule,
                customizedRule: self.customizedRule
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
