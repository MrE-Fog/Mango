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

struct MGRouteSettingRuleView: View {
        
    @Binding var currentEditingRouteID: String
    @Binding var rule: MGRouteModel.Rule
    
    @State private var domain: String = ""
    
    var body: some View {
        DisclosureGroup(isExpanded: .constant(self.currentEditingRouteID == rule.__id__.uuidString)) {
            Group {
                LabeledContent("规则名称") {
                    TextField("", text: $rule.__name__)
                }
                Picker("匹配算法", selection: $rule.domainMatcher) {
                    ForEach(MGRouteModel.DomainMatcher.allCases) { strategy in
                        Text(strategy.description)
                    }
                }
            }
            Group {
                MGStringListDisclosureGroup(title: "域名", prompt: "输入域名", elements: $rule.domain)
                MGStringListDisclosureGroup(title: "IP", prompt: "输入 IP", elements: $rule.ip)
            }
            Group {
                LabeledContent("目标端口") {
                    TextField("", text: $rule.port)
                }
                LabeledContent("来源端口") {
                    TextField("", text: $rule.sourcePort)
                }
                LabeledContent("网络") {
                    TextField("", text: $rule.network)
                }
            }
            Group {
                MGStringListDisclosureGroup(title: "来源 IP", prompt: "输入来源 IP", elements: $rule.user)
                MGStringListDisclosureGroup(title: "来源用户", prompt: "输入来源用户", elements: $rule.user)
            }
            Group {
                LabeledContent("协议") {
                    TextField("", text: $rule.attrs)
                }
                LabeledContent("脚本") {
                    TextField("", text: $rule.attrs)
                }
                LabeledContent("出站标识") {
                    TextField("", text: $rule.outboundTag)
                }
            }
        } label: {
            HStack {
                Text(rule.__name__)
                Spacer()
                Toggle("", isOn: $rule.__enabled__)
                    .labelsHidden()
                    .fixedSize()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    if self.currentEditingRouteID == rule.__id__.uuidString {
                        self.currentEditingRouteID = ""
                    } else {
                        self.currentEditingRouteID = rule.__id__.uuidString
                    }
                }
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
    }
}

struct MGStringListDisclosureGroup: View {
    
    @State private var value: String = ""
    
    let title: String
    let prompt: String
    
    @Binding var elements: [String]
    
    var body: some View {
        DisclosureGroup {
            ForEach(Array(elements.enumerated()), id: \.element) { pair in
                Text(pair.element)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("删除", role: .destructive) {
                            elements.remove(at: pair.offset)
                        }
                    }
            }
            TextField(prompt, text: $value)
                .multilineTextAlignment(.leading)
                .onSubmit {
                    let reval = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !reval.isEmpty && !elements.contains(reval) {
                        elements.append(reval)
                    }
                    value = ""
                }
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text("\(elements.count)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MGRouteRuleSettingView: View {
    
    @Binding var rule: MGRouteModel.Rule
    
    var body: some View {
        Text("")
    }
}
