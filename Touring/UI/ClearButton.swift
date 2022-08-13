import SwiftUI

struct ClearButton: ViewModifier {
    @Binding private var text: String
    private var focused: FocusState<Bool>.Binding?
    private var imageName: String
    @Environment(\.isEnabled) private var isEnabled

    init(text: Binding<String>, focused: FocusState<Bool>.Binding? = nil, imageName: String = "xmark.circle.fill") {
        self._text = text
        self.focused = focused
        self.imageName = imageName
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .trailing) {
                if !text.isEmpty && isEnabled {
                    Button {
                        text = ""
                        focused?.wrappedValue = true
                    } label: {
                        Image(systemName: imageName)
                            .foregroundColor(.secondary)
                            .padding(10)
                    }
                    // Make this work even in a Form
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
    }
}

extension View {
    func clearButton(text: Binding<String>, focused: FocusState<Bool>.Binding? = nil,
                     imageName: String = "xmark.circle.fill") -> some View {
        modifier(ClearButton(text: text, focused: focused, imageName: imageName))
    }
}
