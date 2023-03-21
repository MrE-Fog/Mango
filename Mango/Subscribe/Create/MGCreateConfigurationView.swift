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
                    Text("Setting")
                }
                Section {
                    NavigationLink {
                        MGConfigurationNetworkView(vm: vm)
                    } label: {
                        LabeledContent("Network", value: vm.streamSettings.network.description)
                    }
                    NavigationLink {
                        MGConfigurationSecurityView(vm: vm)
                    } label: {
                        LabeledContent("Security", value: vm.streamSettings.security.description)
                    }
                } header: {
                    Text("Stream Setting")
                }
                Section {
                    Toggle("Enable", isOn: $vm.mux.enabled)
                    LabeledContent("Concurrency") {
                        TextField("", value: $vm.mux.concurrency, format: .number)
                    }
                } header: {
                    Text("Mux")
                }
                Section {
                    LabeledContent("Description") {
                        TextField("", text: $vm.descriptive)
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
}
