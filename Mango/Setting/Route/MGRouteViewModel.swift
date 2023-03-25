import Foundation

final class MGRouteViewModel: ObservableObject {
    
    @Published var domainStrategy: MGRouteModel.DomainStrategy
    @Published var domainMatcher: MGRouteModel.DomainMatcher
    @Published var rules: [MGRouteModel.Rule]
    @Published var balancers: [MGRouteModel.Balancer]
    
    init() {
        let model = MGRouteModel.current
        self.domainStrategy = model.domainStrategy
        self.domainMatcher = model.domainMatcher
        self.rules = model.rules
        self.balancers = model.balancers
    }
    
    static func setupDefaultSettingsIfNeeded() {
        guard UserDefaults.shared.data(forKey: MGConstant.route) == nil else {
            return
        }
        do {
            UserDefaults.shared.set(try JSONEncoder().encode(MGRouteModel.default), forKey: MGConstant.route)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func save(updated: () -> Void) {
        do {
            let model = MGRouteModel(
                domainStrategy: self.domainStrategy,
                domainMatcher: self.domainMatcher,
                rules: self.rules,
                balancers: self.balancers
            )
            guard model != .current else {
                return
            }
            UserDefaults.shared.set(try JSONEncoder().encode(model), forKey: MGConstant.route)
            updated()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
