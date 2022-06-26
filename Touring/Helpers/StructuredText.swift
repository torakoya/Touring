import SwiftUI

/// Generates a SwiftUI view from Markdown.
///
/// This can:
/// * Interpret Markdown.
/// * Also interpret some Markdown block elements.
/// * Embed system symbol images with `!(...)`.
///
/// Why this should be used:
/// * Text, AttributedString, and NSAttributedString can't seem to
///   interpret Markdown block elements.
/// * MKWebView can't seem to display system symbol images.
/// * An NSAttributedString with an attachment of a system symbol image
///   seems drop the image when it gets wrapped in a SwiftUI Text.
class StructuredText {
    var olIndex = 0
    var lineSpacing = 10.0
    var indentSpacing = 20.0
    var localizing = true

    static func fromAsset(name: NSDataAssetName, localizing: Bool = true) -> some View {
        if let data = NSDataAsset(name: name),
            let source = String(data: data.data, encoding: .utf8) {
            return AnyView(fromSource(source, localizing: localizing))
        } else {
            return AnyView(EmptyView())
        }
    }

    static func fromSource(_ body: String, localizing: Bool = true) -> some View {
        let st = StructuredText()
        st.localizing = localizing
        let lines = body.components(separatedBy: .newlines)

        return VStack(alignment: .leading) {
            ForEach(lines, id: \.self) { line in
                if line.hasPrefix("# ") {
                    st.title(String(line.dropFirst(2)))
                } else if line.hasPrefix("## ") {
                    st.heading(String(line.dropFirst(3)))
                } else if line.hasPrefix("1. ") {
                    st.oli(String(line.dropFirst(3)))
                } else if line.hasPrefix("* ") {
                    st.uli(String(line.dropFirst(2)))
                } else if line.hasPrefix("  * ") {
                    st.uli(1, String(line.dropFirst(4)))
                } else if !line.isEmpty {
                    st.p(line)
                }
            }
        }
    }

    /// Convert the string to a Text.
    ///
    /// The strings will be localized, interpreted as Markdown, and made `!(...)` converted to a system symbol image.
    static func text(_ string: String, localizing: Bool = true) -> Text {
        let lstr = localizing ? String(localized: String.LocalizationValue(string)) : string
        let astr = (try? AttributedString(markdown: lstr)) ?? AttributedString(lstr)
        return imageEmbeddedText(astr)
    }

    static func imageEmbeddedText(_ attributedString: AttributedString) -> Text {
        // Convert the AttributedString to an NSAttributedString.
        // AttributedString can't be used because:
        // * There is no way to get the string an AttributedString
        //   contains.
        // * AttributedString can find only the first match of a regular
        //   expression.
        let nsastr = NSAttributedString(attributedString)
        var result = Text("")

        var start = 0
        if let re = try? NSRegularExpression(pattern: #"(?:!\((.*?)\))|$"#) {
            let matches = re.matches(in: nsastr.string, range: NSRange(location: 0, length: nsastr.string.count))
            for match in matches {
                if match.range.lowerBound - start > 0 {
                    let range = NSRange(location: start, length: match.range.lowerBound - start)
                    let before = nsastr.attributedSubstring(from: range)
                    // swiftlint:disable:next shorthand_operator
                    result = result + Text(AttributedString(before))
                }

                if match.range(at: 1).lowerBound != NSNotFound {
                    let imgname = nsastr.attributedSubstring(from: match.range(at: 1)).string
                    // swiftlint:disable:next shorthand_operator
                    result = result + Text(Image(systemName: imgname))
                }

                start = match.range.upperBound
            }
        }

        return result
    }

    func title(_ string: String) -> some View {
        olIndex = 0
        return Self.text(string, localizing: localizing)
            .font(.largeTitle)
            .lineSpacing(lineSpacing)
            .padding(.bottom)
    }

    func heading(_ string: String) -> some View {
        olIndex = 0
        return Self.text(string, localizing: localizing)
            .font(.title)
            .lineSpacing(lineSpacing)
            .padding(.bottom)
    }

    func p(_ string: String) -> some View {
        olIndex = 0
        return Self.text(string, localizing: localizing)
            .lineSpacing(lineSpacing)
            .padding(.bottom)
    }

    func oli(_ string: String) -> some View {
        olIndex += 1
        return HStack(alignment: .firstTextBaseline) {
            Text("\(olIndex).")
            Self.text(string, localizing: localizing)
                .lineSpacing(lineSpacing)
        }
        .padding(.bottom)
    }

    func uli(_ indent: Int, _ string: String) -> some View {
        if indent == 0 { olIndex = 0 }
        return HStack(alignment: .firstTextBaseline) {
            Text("\u{2022}")
                .padding(.leading, indentSpacing * Double(indent))
            Self.text(string, localizing: localizing)
                .lineSpacing(lineSpacing)
        }
        .padding(.bottom)
    }

    func uli(_ string: String) -> some View {
        uli(0, string)
    }
}
