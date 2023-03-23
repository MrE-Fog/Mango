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
                Picker("策略", selection: $routeViewModel.domainStrategy) {
                    ForEach(MGConfiguration.RouteDomainStrategy.allCases) { strategy in
                        Text(strategy.description)
                    }
                }
            } header: {
                Text("域名解析")
            }
            Section {
                Toggle("使用预定义规则", isOn: $routeViewModel.usingPredefinedRule)
                    .disabled(true)
                if routeViewModel.usingPredefinedRule {
                    Picker("预定义规则", selection: $routeViewModel.predefinedRule) {
                        ForEach(MGConfiguration.RoutePredefinedRule.allCases) { rule in
                            Text(rule.description)
                        }
                    }
                } else {
                    Text(routeViewModel.customizedRule)
                }
            } header: {
                Text("规则")
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
