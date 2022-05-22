import SwiftUI

struct Panel: ViewModifier {
    let padding: CGFloat?

    func body(content: Content) -> some View {
        (padding.map { AnyView(content.padding($0)) } ?? AnyView(content.padding()))
            .background(Color(uiColor: .systemBackground).opacity(0.4))
            .cornerRadius(15)
            .shadow(radius: 10)
    }
}

extension View {
    func panel(padding: CGFloat? = nil) -> some View {
        modifier(Panel(padding: padding))
    }
}
