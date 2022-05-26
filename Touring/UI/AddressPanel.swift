import SwiftUI

struct AddressPanel: View {
    @EnvironmentObject private var vm: ContentViewModel

    var addressText: Text? {
        guard let address = vm.mapViewContext.address else { return nil }

        var ss = address.map { $0.map { Text($0) } }
        ss[1] = ss[1].map { $0.bold() }
        if Locale.current.languageCode != "ja" {
            ss = ss.reversed()
        }

        return joinedText(ss, separator: Text(Locale.current.languageCode == "ja" ? " " : ", "))
    }

    func joinedText(_ texts: [Text?], separator: Text = Text("")) -> Text {
        texts.compactMap { $0 }.flatMap { [separator, $0] }.dropFirst().reduce(Text(""), +)
    }

    var body: some View {
        if let addressText = addressText {
            addressText
                .shadow(color: Color(uiColor: .systemBackground), radius: 1) // For visibility of the text.
                .panel(padding: 10)
                .allowsHitTesting(false)
        }
    }
}

struct AddressPanel_Previews: PreviewProvider {
    static var previews: some View {
        AddressPanel()
            .environmentObject(ContentViewModel())
    }
}
