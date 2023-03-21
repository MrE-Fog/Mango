import SwiftUI

struct MGConfigurationShadowsocksView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
    
    var body: some View {
        LabeledContent("Address") {
            TextField("", text: $vm.shadowsocks.servers[0].address)
        }
        LabeledContent("Port") {
            TextField("", value: $vm.shadowsocks.servers[0].port, format: .number)
        }
        LabeledContent("Email") {
            TextField("", text: $vm.shadowsocks.servers[0].email)
        }
        LabeledContent("Password") {
            TextField("", text: $vm.shadowsocks.servers[0].password)
        }
        Picker("Method", selection: $vm.shadowsocks.servers[0].method) {
            ForEach(MGConfiguration.Shadowsocks.Method.allCases) { method in
                Text(method.description)
            }
        }
        Toggle("UOT", isOn: $vm.shadowsocks.servers[0].uot)
    }
}
