import SwiftUI

struct MGConfigurationSecurityView: View {
    
    @ObservedObject private var vm: MGCreateConfigurationViewModel
    
    init(vm: MGCreateConfigurationViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Security", selection: $vm.streamSettings.security) {
                    ForEach(MGConfiguration.Security.allCases) { type in
                        Text(type.description)
                    }
                }
            }
            switch vm.streamSettings.security {
            case .tls:
                Section {
                    LabeledContent("Server Name") {
                        TextField("", text: $vm.streamSettings.tlsSettings.serverName)
                    }
                    LabeledContent("Fingerprint") {
                        Picker("", selection: $vm.streamSettings.tlsSettings.fingerprint) {
                            ForEach(MGConfiguration.Fingerprint.allCases) { fingerprint in
                                Text(fingerprint.description)
                            }
                        }
                    }
                    Toggle("Allow Insecure", isOn: $vm.streamSettings.tlsSettings.allowInsecure)
                }
            case .reality:
                Section {
                    LabeledContent("Server Name") {
                        TextField("", text: $vm.streamSettings.realitySettings.serverName)
                    }
                    LabeledContent("Fingerprint") {
                        Picker("", selection: $vm.streamSettings.realitySettings.fingerprint) {
                            ForEach(MGConfiguration.Fingerprint.allCases) { fingerprint in
                                Text(fingerprint.description)
                            }
                        }
                    }
                    LabeledContent("Public Key") {
                        TextField("", text: $vm.streamSettings.realitySettings.publicKey)
                    }
                    LabeledContent("Short ID") {
                        TextField("", text: $vm.streamSettings.realitySettings.shortId)
                    }
                    LabeledContent("SpiderX") {
                        TextField("", text: $vm.streamSettings.realitySettings.spiderX)
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
