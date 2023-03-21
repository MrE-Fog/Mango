import SwiftUI

struct MGConfigurationVlESSView: View {
    
    var body: some View {
        LabeledContent("Address") {
            TextField("", text: .constant(""))
        }
        LabeledContent("Port") {
            TextField("", text: .constant(""))
        }
        LabeledContent("UUID") {
            TextField("", text: .constant(""))
        }
        Picker("Encryption", selection: .constant(MGConfiguration.Encryption.none)) {
            ForEach(MGConfiguration.Encryption.vless) { encryption in
                Text(encryption.description)
            }
        }
        Picker("Flow", selection: .constant(MGConfiguration.Flow.none)) {
            ForEach(MGConfiguration.Flow.allCases) { encryption in
                Text(encryption.description)
            }
        }
    }
}
