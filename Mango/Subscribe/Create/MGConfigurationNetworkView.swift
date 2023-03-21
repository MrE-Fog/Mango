import SwiftUI

struct MGConfigurationNetworkView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
        
    var body: some View {
        Form {
            Section {
                Picker("Network", selection: $vm.streamSettings.network) {
                    ForEach(MGConfiguration.Network.allCases) { type in
                        Text(type.description)
                    }
                }
            }
            switch vm.streamSettings.network {
            case .tcp:
                EmptyView()
            case .kcp:
                Section {
                    LabeledContent("MTU") {
                        TextField("", value: $vm.streamSettings.kcpSettings.mtu, format: .number)
                    }
                    LabeledContent("TTI") {
                        TextField("", value: $vm.streamSettings.kcpSettings.tti, format: .number)
                    }
                    LabeledContent("Uplink Capacity") {
                        TextField("", value: $vm.streamSettings.kcpSettings.uplinkCapacity, format: .number)
                    }
                    LabeledContent("Downlink Capacity") {
                        TextField("", value: $vm.streamSettings.kcpSettings.downlinkCapacity, format: .number)
                    }
                    Toggle("Congestion", isOn: .constant(false))
                    LabeledContent("Read Buffer Size") {
                        TextField("", value: $vm.streamSettings.kcpSettings.readBufferSize, format: .number)
                    }
                    LabeledContent("Write Buffer Size") {
                        TextField("", value: $vm.streamSettings.kcpSettings.writeBufferSize, format: .number)
                    }
                    Picker("Header Type", selection: $vm.streamSettings.kcpSettings.header.type) {
                        ForEach(MGConfiguration.HeaderType.allCases) { type in
                            Text(type.description)
                        }
                    }
                    LabeledContent("Seed") {
                        TextField("", text: $vm.streamSettings.kcpSettings.seed)
                    }
                }
            case .ws:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: $vm.streamSettings.wsSettings._host)
                    }
                    LabeledContent("Path") {
                        TextField("", text: $vm.streamSettings.wsSettings.path)
                    }
                }
            case .http:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: $vm.streamSettings.httpSettings._host)
                    }
                    LabeledContent("Path") {
                        TextField("", text: $vm.streamSettings.httpSettings.path)
                    }
                }
            case .quic:
                Section {
                    Picker("Security", selection: $vm.streamSettings.quicSettings.security) {
                        ForEach(MGConfiguration.Encryption.quic) { encryption in
                            Text(encryption.description)
                        }
                    }
                    LabeledContent("Key") {
                        TextField("", text: $vm.streamSettings.quicSettings.key)
                    }
                    Picker("Header Type", selection: $vm.streamSettings.quicSettings.header.type) {
                        ForEach(MGConfiguration.HeaderType.allCases) { type in
                            Text(type.description)
                        }
                    }
                }
            case .grpc:
                Section {
                    LabeledContent("Service Name") {
                        TextField("", text: $vm.streamSettings.grpcSettings.serviceName)
                    }
                    Toggle("Multi-Mode", isOn: $vm.streamSettings.grpcSettings.multiMode)
                }
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
        .navigationTitle(Text("Network"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
