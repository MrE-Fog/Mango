import SwiftUI

struct MGConfigurationVMessView: View {
    
    var body: some View {
        LabeledContent("Address") {
            TextField("", text: .constant(""))
        }
        LabeledContent("Port") {
            TextField("", text: .constant(""))
        }
        LabeledContent("ID") {
            TextField("", text: .constant(""))
        }
        LabeledContent("Alert ID") {
            TextField("", text: .constant(""))
        }
        Picker("Encryption", selection: .constant(MGConfiguration.Encryption.none)) {
            ForEach(MGConfiguration.Encryption.vmess) { encryption in
                Text(encryption.description)
            }
        }
    }
}
