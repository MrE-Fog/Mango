import SwiftUI

struct MGConfigurationVLESSView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
    
    var body: some View {
        LabeledContent("Address") {
            TextField("", text: $vm.vless.address)
        }
        LabeledContent("Port") {
            TextField("", value: $vm.vless.port, format: .number)
        }
        LabeledContent("UUID") {
            TextField("", text: $vm.vless.users[0].id)
        }
        Picker("Encryption", selection: $vm.vless.users[0].encryption) {
            ForEach(MGConfiguration.Encryption.vless) { encryption in
                Text(encryption.description)
            }
        }
        Picker("Flow", selection: $vm.vless.users[0].flow) {
            ForEach(MGConfiguration.Flow.allCases) { encryption in
                Text(encryption.description)
            }
        }
    }
}
