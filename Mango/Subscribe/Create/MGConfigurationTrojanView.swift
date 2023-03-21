import SwiftUI

struct MGConfigurationTrojanView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
    
    var body: some View {
        LabeledContent("Address") {
            TextField("", text: $vm.trojan.servers[0].address)
        }
        LabeledContent("Port") {
            TextField("", value: $vm.trojan.servers[0].port, format: .number)
        }
        LabeledContent("Password") {
            TextField("", text: $vm.trojan.servers[0].password)
        }
        LabeledContent("Email") {
            TextField("", text: $vm.trojan.servers[0].email)
        }
    }
}
