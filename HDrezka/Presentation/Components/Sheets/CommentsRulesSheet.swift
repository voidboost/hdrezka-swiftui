import Defaults
import SwiftUI

struct CommentsRulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Default(.allowedComments) private var allowedComments
    @Default(.mirror) private var mirror

    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(alignment: .center, spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)

                Text("key.rules")
                    .font(.largeTitle.weight(.semibold))

                Text("key.rules.description")
                    .font(.title3)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
            }

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("key.rules.prohibited")

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.inciting").lowercased())
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.insulting").lowercased())
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.obscene").lowercased())
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.spoiler").lowercased())
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.leave").lowercased())
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.questions").lowercased())
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.resources").lowercased())
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.mention").lowercased())
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "seal.fill")
                            .padding(.top, 3)
                            .font(.system(size: 9))
                            .foregroundStyle(.accent)

                        Text(String(localized: "key.rules.problems").lowercased())
                    }
                }
                .multilineTextAlignment(.leading)
                .font(.system(size: 13))
                .padding(10)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.never)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(.quinary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.tertiary, lineWidth: 1)
            }

            VStack(alignment: .center, spacing: 10) {
                Button {
                    if let cookie = HTTPCookie(properties: [
                        .name: "allowed_comments",
                        .value: "1",
                        .domain: ".\(mirror.replacingOccurrences(of: "/", with: "").components(separatedBy: ":").last ?? "")",
                        .path: "/",
                        .expires: Date.now.addingTimeInterval(30 * 24 * 60 * 60)
                    ]) {
                        HTTPCookieStorage.shared.setCookie(cookie)

                        allowedComments = true
                    }

                    dismiss()
                } label: {
                    Text("key.accept")
                        .frame(width: 250, height: 30)
                        .foregroundStyle(.white)
                        .background(.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text("key.cancel")
                        .frame(width: 250, height: 30)
                        .background(.quinary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 520)
    }
}
