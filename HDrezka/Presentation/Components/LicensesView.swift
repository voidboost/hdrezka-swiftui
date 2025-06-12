import LicensesList
import SwiftUI

struct LicensesView: View {
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Library.libraries) { library in
                    LicenseView(library: library)

                    if Library.libraries.last != library {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 15)
            .background(.quinary)
            .clipShape(.rect(cornerRadius: 6))
            .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
            .padding(25)
            .background(.background)
        }
        .scrollIndicators(.never)
        .navigationTitle("key.licenses")
        .frame(width: 700, height: 400)
    }

    private struct LicenseView: View {
        private let library: Library

        @State private var showLicense = false

        init(library: Library) {
            self.library = library
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(library.name)
                        .font(.title)
                        .textSelection(.enabled)

                    Text(library.version)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }

                if let url = library.url {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Text(url.absoluteString)
                    }
                    .buttonStyle(.link)
                }

                Button {
                    withAnimation(.easeInOut) {
                        showLicense.toggle()
                    }
                } label: {
                    Label(showLicense ? String(localized: "key.license.hide") : String(localized: "key.license.show"), systemImage: showLicense ? "chevron.up" : "chevron.down")
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)

                if showLicense {
                    Text(attribute(library.licenseBody))
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .padding()
                }
            }
            .padding(.vertical, 10)
        }

        private func attribute(_ inputText: String) -> AttributedString {
            var attributedText = AttributedString(inputText)
            let urls: [URL?] = inputText.match(URL.regexPattern)
                .map { URL(string: String(inputText[$0])) }
            let ranges = attributedText.match(URL.regexPattern)
            for case let (range, url?) in zip(ranges, urls) {
                attributedText[range].link = url
            }
            return attributedText
        }
    }
}

extension URL {
    static let regexPattern = "https?://[A-Za-z0-9-.!@#$%&=+/?:_~]+"
}

extension StringProtocol {
    func match(_ pattern: String) -> [Range<Index>] {
        guard let range = range(of: pattern, options: .regularExpression) else {
            return []
        }
        return [range] + self[range.upperBound...].match(pattern)
    }
}

extension AttributedStringProtocol {
    func match(_ pattern: String) -> [Range<AttributedString.Index>] {
        guard let range = range(of: pattern, options: .regularExpression) else {
            return []
        }
        return [range] + self[range.upperBound...].match(pattern)
    }
}
