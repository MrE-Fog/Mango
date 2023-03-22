import SwiftUI

struct MGCreateConfigurationView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    @Environment(\.dismiss) private var dismiss
        
    init(protocolType: MGConfiguration.ProtocolType) {
        self._vm = ObservedObject(initialValue: MGCreateConfigurationViewModel(protocolType: protocolType))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Description") {
                        TextField("", text: $vm.descriptive)
                    }
                    switch vm.protocolType {
                    case .vless:
                        MGConfigurationVLESSView(vm: vm)
                    case .vmess:
                        MGConfigurationVMessView(vm: vm)
                    case .trojan:
                        MGConfigurationTrojanView(vm: vm)
                    case .shadowsocks:
                        MGConfigurationShadowsocksView(vm: vm)
                    }
                } header: {
                    Text("Server")
                }
                if isTransportAvailable {
                    Section {
                        Picker("Transport", selection: $vm.network) {
                            ForEach(MGConfiguration.Network.allCases) { type in
                                Text(type.description)
                            }
                        }
                        MGConfigurationNetworkView(vm: vm)
                    } header: {
                        Text("Transport")
                    }
                }
                if isSecurityAvailable {
                    Section {
                        Picker("Security", selection: $vm.security) {
                            ForEach(MGConfiguration.Security.allCases) { type in
                                Text(type.description)
                            }
                        }
                        MGConfigurationSecurityView(vm: vm)
                    } header: {
                        Text("Security")
                    }
                }
                if isMuxAvailable {
                    Section {
                        Toggle("Enable", isOn: $vm.mux.enabled)
                        LabeledContent("Concurrency") {
                            TextField("", value: $vm.mux.concurrency, format: .number)
                        }
                    } header: {
                        Text("Mux")
                    }
                }
            }
            .lineLimit(1)
            .multilineTextAlignment(.trailing)
            .navigationTitle(Text(vm.protocolType.description))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var isTransportAvailable: Bool {
        switch vm.protocolType {
        case .shadowsocks:
             return false
        case .vless, .vmess, .trojan:
            return true
        }
    }
    
    private var isSecurityAvailable: Bool {
        switch vm.protocolType {
        case .shadowsocks:
             return false
        case .vless, .vmess, .trojan:
            return true
        }
    }
    
    private var isMuxAvailable: Bool {
        switch vm.protocolType {
        case .shadowsocks:
             return false
        case .vless, .vmess, .trojan:
            return true
        }
    }
}
