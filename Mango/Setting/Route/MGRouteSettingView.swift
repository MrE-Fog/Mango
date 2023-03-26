import SwiftUI

struct MGRouteSettingView: View {
    
    @EnvironmentObject  private var packetTunnelManager:    MGPacketTunnelManager
    @ObservedObject     private var routeViewModel:         MGRouteViewModel
            
    @Environment(\.editMode) var editMode
    
    init(routeViewModel: MGRouteViewModel) {
        self._routeViewModel = ObservedObject(initialValue: routeViewModel)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("解析策略", selection: $routeViewModel.domainStrategy) {
                    ForEach(MGRouteModel.DomainStrategy.allCases) { strategy in
                        Text(strategy.description)
                    }
                }
                Picker("匹配算法", selection: $routeViewModel.domainMatcher) {
                    ForEach(MGRouteModel.DomainMatcher.allCases) { strategy in
                        Text(strategy.description)
                    }
                }
            } header: {
                Text("域名")
            }
            Section {
                ForEach($routeViewModel.rules) { rule in
                    NavigationLink {
                        MGRouteRuleSettingView(rule: rule)
                    } label: {
                        HStack {
                            LabeledContent {
                                Text(rule.outboundTag.wrappedValue)
                            } label: {
                                Label {
                                    Text(rule.__name__.wrappedValue)
                                } icon: {
                                    Image(systemName: "circle.fill")
                                        .resizable()
                                        .frame(width: 8, height: 8)
                                        .foregroundColor(rule.__enabled__.wrappedValue ? .green : .red)
                                }
                            }
                        }
                    }
                }
                .onMove { from, to in
                    routeViewModel.rules.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { offsets in
                    routeViewModel.rules.remove(atOffsets: offsets)
                }
                Button("添加规则") {
                    withAnimation {
                        routeViewModel.rules.append(MGRouteModel.Rule())
                    }
                }
                .disabled(self.editMode.flatMap({ $0.wrappedValue == .active }) ?? true)
            } header: {
                HStack {
                    Text("规则")
                    Spacer()
                    EditButton()
                        .font(.callout)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                }
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

struct MGRouteRuleSettingView: View {
    
    @Binding var rule: MGRouteModel.Rule
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Name") {
                    TextField("", text: $rule.__name__)
                }
                Picker("Matcher", selection: $rule.domainMatcher) {
                    ForEach(MGRouteModel.DomainMatcher.allCases) { strategy in
                        Text(strategy.description)
                    }
                }
                NavigationLink {
                    MGRouteRuleStringListEditView(title: "Domain", elements: $rule.domain)
                } label: {
                    LabeledContent("Domain", value: "\(rule.domain.count)")
                }
                NavigationLink {
                    MGRouteRuleStringListEditView(title: "IP", elements: $rule.ip)
                } label: {
                    LabeledContent("IP", value: "\(rule.ip.count)")
                }
                LabeledContent("Port") {
                    TextField("", text: $rule.sourcePort)
                }
                LabeledContent("Source Port") {
                    TextField("", text: $rule.port)
                }
                LabeledContent("Network") {
                    HStack {
                        MGToggleButton(title: "TCP", isOn: Binding(get: {
                            rule.network.components(separatedBy: ",").contains("tcp")
                        }, set: { newValue in
                            var components = rule.network.components(separatedBy: ",")
                            components.removeAll(where: { $0 == "tcp" })
                            if newValue {
                                components.insert("tcp", at: 0)
                            }
                            rule.network = String(components.joined(separator: ","))
                        }))
                        MGToggleButton(title: "UDP", isOn: Binding(get: {
                            rule.network.components(separatedBy: ",").contains("udp")
                        }, set: { newValue in
                            var components = rule.network.components(separatedBy: ",")
                            components.removeAll(where: { $0 == "udp" })
                            if newValue {
                                components.append("udp")
                            }
                            rule.network = String(components.joined(separator: ","))
                        }))
                    }
                }
                LabeledContent("Protocol") {
                    HStack {
                        MGToggleButton(title: "HTTP", isOn: Binding(get: {
                            rule.protocol.contains("http")
                        }, set: { newValue in
                            rule.protocol.removeAll(where: { $0 == "http" })
                            if newValue {
                                rule.protocol.append("http")
                            }
                        }))
                        MGToggleButton(title: "TLS", isOn: Binding(get: {
                            rule.protocol.contains("tls")
                        }, set: { newValue in
                            rule.protocol.removeAll(where: { $0 == "tls" })
                            if newValue {
                                rule.protocol.append("tls")
                            }
                        }))
                        MGToggleButton(title: "Bittorrent", isOn: Binding(get: {
                            rule.protocol.contains("bittorrent")
                        }, set: { newValue in
                            rule.protocol.removeAll(where: { $0 == "bittorrent" })
                            if newValue {
                                rule.protocol.append("bittorrent")
                            }
                        }))
                    }
                }
                LabeledContent("Outbound") {
                    TextField("", text: $rule.outboundTag)
                }
            } header: {
                Text("Settings")
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
        .navigationTitle(Text(rule.__name__))
        .navigationBarTitleDisplayMode(.large)
    }
}

struct MGRouteRuleStringListEditView: View {
    
    let title: String
    @Binding var elements: [String]
    
    @State private var isPresented: Bool = false
    @State private var value: String = ""
    
    var body: some View {
        Form {
            Section {
                ForEach(elements, id: \.self) { element in
                    Text(element)
                }
                .onMove { from, to in
                    elements.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { offseets in
                    elements.remove(atOffsets: offseets)
                }
                
            } header: {
                Text("List")
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.large)
        .alert("Add", isPresented: $isPresented) {
            TextField("", text: $value)
            Button("Done") {
                let reavl = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !reavl.isEmpty && !elements.contains(reavl) {
                    elements.append(reavl)
                }
                value = ""
            }
            Button("Cancel", role: .cancel) {}
        }
        .toolbar {
            Button {
                isPresented.toggle()
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
