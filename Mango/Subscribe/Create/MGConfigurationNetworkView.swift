import SwiftUI

struct MGConfigurationNetworkView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
        
    var body: some View {
        Form {
            Section {
                Picker("Network", selection: $vm.network) {
                    ForEach(MGConfiguration.Network.allCases) { type in
                        Text(type.description)
                    }
                }
            }
            switch vm.network {
            case .tcp:
                EmptyView()
            case .kcp:
                Section {
                    LabeledContent("MTU") {
                        TextField("", value: $vm.kcp.mtu, format: .number)
                    }
                    LabeledContent("TTI") {
                        TextField("", value: $vm.kcp.tti, format: .number)
                    }
                    LabeledContent("Uplink Capacity") {
                        TextField("", value: $vm.kcp.uplinkCapacity, format: .number)
                    }
                    LabeledContent("Downlink Capacity") {
                        TextField("", value: $vm.kcp.downlinkCapacity, format: .number)
                    }
                    Toggle("Congestion", isOn: .constant(false))
                    LabeledContent("Read Buffer Size") {
                        TextField("", value: $vm.kcp.readBufferSize, format: .number)
                    }
                    LabeledContent("Write Buffer Size") {
                        TextField("", value: $vm.kcp.writeBufferSize, format: .number)
                    }
                    Picker("Header Type", selection: $vm.kcp.header.type) {
                        ForEach(MGConfiguration.HeaderType.allCases) { type in
                            Text(type.description)
                        }
                    }
                    LabeledContent("Seed") {
                        TextField("", text: $vm.kcp.seed)
                    }
                }
            case .ws:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: $vm.ws._host)
                    }
                    LabeledContent("Path") {
                        TextField("", text: $vm.ws.path)
                    }
                }
            case .http:
                Section {
                    LabeledContent("Host") {
                        TextField("", text: $vm.http._host)
                    }
                    LabeledContent("Path") {
                        TextField("", text: $vm.http.path)
                    }
                }
            case .quic:
                Section {
                    Picker("Security", selection: $vm.quic.security) {
                        ForEach(MGConfiguration.Encryption.quic) { encryption in
                            Text(encryption.description)
                        }
                    }
                    LabeledContent("Key") {
                        TextField("", text: $vm.quic.key)
                    }
                    Picker("Header Type", selection: $vm.quic.header.type) {
                        ForEach(MGConfiguration.HeaderType.allCases) { type in
                            Text(type.description)
                        }
                    }
                }
            case .grpc:
                Section {
                    LabeledContent("Service Name") {
                        TextField("", text: $vm.grpc.serviceName)
                    }
                    Toggle("Multi-Mode", isOn: $vm.grpc.multiMode)
                }
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
        .navigationTitle(Text("Network"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
