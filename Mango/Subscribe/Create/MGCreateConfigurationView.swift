import SwiftUI

struct MGCreateConfigurationView: View {
    
    @ObservedObject private var vm = MGCreateConfigurationViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    let `protocol`: MGConfiguration.ProtocolType
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    switch `protocol` {
                    case .vless:
                        MGConfigurationVlESSView()
                    case .vmess:
                        MGConfigurationVMessView()
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
            .navigationTitle(Text(`protocol`.description))
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
