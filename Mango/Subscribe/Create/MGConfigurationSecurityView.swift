import SwiftUI

struct MGConfigurationSecurityView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Security", selection: $vm.security) {
                    ForEach(MGConfiguration.Security.allCases) { type in
                        Text(type.description)
                    }
                }
            }
            switch vm.security {
            case .tls:
                Section {
                    LabeledContent("Server Name") {
                        TextField("", text: $vm.tls.serverName)
                    }
                    LabeledContent("Fingerprint") {
                        Picker("", selection: $vm.tls.fingerprint) {
                            ForEach(MGConfiguration.Fingerprint.allCases) { fingerprint in
                                Text(fingerprint.description)
                            }
                        }
                    }
                    Toggle("Allow Insecure", isOn: $vm.tls.allowInsecure)
                }
            case .reality:
                Section {
                    LabeledContent("Server Name") {
                        TextField("", text: $vm.reality.serverName)
                    }
                    LabeledContent("Fingerprint") {
                        Picker("", selection: $vm.reality.fingerprint) {
                            ForEach(MGConfiguration.Fingerprint.allCases) { fingerprint in
                                Text(fingerprint.description)
                            }
                        }
                    }
                    LabeledContent("Public Key") {
                        TextField("", text: $vm.reality.publicKey)
                    }
                    LabeledContent("Short ID") {
                        TextField("", text: $vm.reality.shortId)
                    }
                    LabeledContent("SpiderX") {
                        TextField("", text: $vm.reality.spiderX)
                    }
                }
            case .none:
                EmptyView()
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
        .navigationTitle(Text("Security"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
