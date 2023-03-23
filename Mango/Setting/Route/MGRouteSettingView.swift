import SwiftUI

struct MGRouteSettingView: View {
    
    @EnvironmentObject  private var packetTunnelManager:    MGPacketTunnelManager
    @ObservedObject     private var routeViewModel:         MGRouteViewModel
    
    init(routeViewModel: MGRouteViewModel) {
        self._routeViewModel = ObservedObject(initialValue: routeViewModel)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("域名策略", selection: $routeViewModel.domainStrategy) {
                    ForEach(MGConfiguration.RouteDomainStrategy.allCases) { strategy in
                        Text(strategy.description)
                    }
                }
                Picker("规则", selection: $routeViewModel.predefinedRule) {
                    ForEach(MGConfiguration.RoutePredefineRule.allCases) { rule in
                        Text(rule.description)
                    }
                }
            } header: {
                Text("预定义路由")
            }
        }
        .onDisappear {
            self.routeViewModel.save {
                guard let status = packetTunnelManager.status, status == .connected else {
                    return
                }
                packetTunnelManager.stop()
                Task(priority: .userInitiated) {
                    do {
                        try await Task.sleep(for: .milliseconds(500))
                        try await packetTunnelManager.start()
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                }
            }
        }
        .navigationTitle(Text("路由设置"))
    }
}
