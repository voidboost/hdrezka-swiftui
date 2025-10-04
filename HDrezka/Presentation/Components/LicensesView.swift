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
            .background(.quinary, in: .rect(cornerRadius: 6))
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
                    Link(destination: url) {
                        Text(url.absoluteString)
                    }
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
                    Text(attributedString(library.licenseBody))
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .padding()
                }
            }
            .padding(.vertical, 10)
        }

        private func attributedString(_ input: String) -> AttributedString {
            var attributedString = AttributedString(input)

            guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
                return attributedString
            }

            let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))

            for match in matches {
                guard let range = Range(match.range, in: input),
                      let attributedRange = Range(match.range, in: attributedString),
                      let url = URL(string: String(input[range]))
                else {
                    continue
                }

                attributedString[attributedRange].link = url
            }

            return attributedString
        }
    }
}
