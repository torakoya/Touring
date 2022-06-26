import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    private let items: [(title: String, file: String)] = [
        ("Plan a Route", "1"),
        ("Run", "2"),
        ("See the Records", "3"),
        ("Transfer Your Data to Another Device", "4")
    ]
    private let locale = Locale.current.languageCode == "ja" ? "ja" : "en"

    var body: some View {
        VStack {
            NavigationView {
                List(items, id: \.file) { item in
                    NavigationLink {
                        ScrollView {
                            StructuredText.fromAsset(name: "Help/\(locale)/\(item.file).md", localizing: false)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding([.leading, .trailing])
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.title)
                                }
                            }
                        }
                    } label: {
                        Text(String(localized: String.LocalizationValue(item.title)))
                    }
                }
                .navigationTitle("Quick Start")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title)
                        }
                    }
                }
            }
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
