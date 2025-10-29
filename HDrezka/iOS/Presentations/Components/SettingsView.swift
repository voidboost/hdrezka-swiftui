import AVFoundation
import Defaults
import Kingfisher
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Default(.mirror) private var currentMirror
    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.defaultQuality) private var defaultQuality
    @Default(.spatialAudio) private var spatialAudio
    @Default(.theme) private var theme
    @Default(.cache) private var cache

    @Environment(\.modelContext) private var modelContext

    @Query(animation: .easeInOut) private var playerPositions: [PlayerPosition]
    @Query(animation: .easeInOut) private var selectPositions: [SelectPosition]

    @State private var mirror: URL?
    @State private var mirrorValid: Bool?
    @State private var mirrorCheck: DispatchWorkItem?

    private let title: String = .init(localized: "key.settings")

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("key.mirror")

                        TextField("key.mirror", value: $mirror, format: .url, prompt: Text(currentMirror.absoluteString))
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .onChange(of: mirror) {
                                withAnimation(.easeInOut) {
                                    mirrorValid = nil
                                }

                                mirrorCheck?.cancel()

                                if mirror != nil {
                                    mirrorCheck = DispatchWorkItem {
                                        withAnimation(.easeInOut) {
                                            mirrorValid = if let mirror,
                                                             !mirror.isFileURL,
                                                             let host = mirror.host(),
                                                             host != currentMirror.host()
                                            {
                                                true
                                            } else {
                                                false
                                            }
                                        }
                                    }

                                    if let mirrorCheck {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: mirrorCheck)
                                    }
                                }
                            }

                        Button {
                            if currentMirror != _currentMirror.defaultValue {
                                migrateCookies(currentMirror, _currentMirror.defaultValue)

                                _currentMirror.reset()
                            }

                            mirrorValid = nil
                            mirrorCheck?.cancel()
                        } label: {
                            Image(systemName: "gobackward")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quinary, in: .rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))

                    if mirrorValid == true, let mirror, var urlComponents = URLComponents(url: mirror, resolvingAgainstBaseURL: false) {
                        Button {
                            urlComponents.scheme = "https"
                            urlComponents.path = "/"
                            urlComponents.port = nil
                            urlComponents.query = nil
                            urlComponents.fragment = nil
                            urlComponents.user = nil
                            urlComponents.password = nil

                            if let newMirror = urlComponents.url, currentMirror != newMirror {
                                migrateCookies(currentMirror, newMirror)

                                currentMirror = newMirror
                            }

                            withAnimation(.easeInOut) {
                                mirrorValid = nil
                            }

                            mirrorCheck?.cancel()
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .bold()
                                .imageFill(1)
                                .contentShape(.rect(cornerRadius: 6))
                                .overlay(Color.accentColor, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 40)

                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("key.theme")

                        Spacer()

                        Picker("key.theme", selection: $theme) {
                            ForEach(Theme.allCases) { theme in
                                Text(theme.localizedKey)
                                    .tag(theme)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .frame(height: 40)

                    Divider()

                    HStack(alignment: .center, spacing: 8) {
                        Text("key.spatialAudio")

                        Spacer()

                        Picker("key.spatialAudio", selection: $spatialAudio) {
                            ForEach(SpatialAudio.allCases) { format in
                                Text(format.localizedKey)
                                    .tag(format)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .frame(height: 40)

                    Divider()

                    HStack(alignment: .center, spacing: 8) {
                        Text("key.defaultQuality")

                        Spacer()

                        Picker("key.defaultQuality", selection: $defaultQuality) {
                            ForEach(DefaultQuality.allCases) { quality in
                                Text(quality.localizedKey)
                                    .tag(quality)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .frame(height: 40)

                    Divider()

                    HStack(alignment: .center, spacing: 8) {
                        Text("key.playerPositions-\(playerPositions.count)")
                            .monospacedDigit()
                            .contentTransition(.numericText(value: Double(playerPositions.count)))

                        Spacer()

                        Button {
                            for position in playerPositions {
                                modelContext.delete(position)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.accentColor)
                                .bold()
                                .imageFill(1)
                                .frame(height: 30)
                                .contentShape(.rect(cornerRadius: 6))
                                .overlay(Color.accentColor, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(playerPositions.isEmpty)
                    }
                    .frame(height: 40)

                    if !isLoggedIn {
                        Divider()

                        HStack(alignment: .center, spacing: 8) {
                            Text("key.selectPositions-\(selectPositions.count)")
                                .monospacedDigit()
                                .contentTransition(.numericText(value: Double(selectPositions.count)))

                            Spacer()

                            Button {
                                for position in selectPositions {
                                    modelContext.delete(position)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.accentColor)
                                    .bold()
                                    .imageFill(1)
                                    .frame(height: 30)
                                    .contentShape(.rect(cornerRadius: 6))
                                    .overlay(Color.accentColor, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(selectPositions.isEmpty)
                        }
                        .frame(height: 40)
                    }

                    Divider()

                    HStack(alignment: .center, spacing: 8) {
                        Text("key.cache")

                        Spacer()

                        Picker("key.cache", selection: $cache) {
                            ForEach(Cache.allCases) { cache in
                                Text(cache.localizedKey)
                                    .tag(cache)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .frame(height: 40)
                    .onChange(of: cache) {
                        let defaultCache = ImageCache.default

                        switch cache {
                        case .off:
                            defaultCache.clearCache()

                            defaultCache.memoryStorage.config.expiration = .expired
                            defaultCache.diskStorage.config.expiration = .expired
                        case .memory:
                            defaultCache.clearDiskCache()

                            defaultCache.memoryStorage.config.expiration = .seconds(300)
                            defaultCache.diskStorage.config.expiration = .expired
                        case .disk:
                            defaultCache.clearMemoryCache()

                            defaultCache.memoryStorage.config.expiration = .expired
                            defaultCache.diskStorage.config.expiration = .days(7)
                        case .all:
                            defaultCache.memoryStorage.config.expiration = .seconds(300)
                            defaultCache.diskStorage.config.expiration = .days(7)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .background(.quinary, in: .rect(cornerRadius: 6))
                .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
            }
            .padding(25)
            .background(.background)
            .onChange(of: currentMirror) {
                mirror = nil
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .viewModifier { view in
            if #available(iOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .transition(.opacity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .background(.background)
    }

    private func migrateCookies(_ from: URL, _ to: URL) {
        if isLoggedIn {
            HTTPCookieStorage.shared.cookies(for: from)?.forEach { cookie in
                var cookieProperties = [HTTPCookiePropertyKey: Any]()
                cookieProperties[.version] = cookie.version
                cookieProperties[.name] = cookie.name
                cookieProperties[.value] = cookie.value
                cookieProperties[.expires] = cookie.expiresDate
                cookieProperties[.domain] = ".\(to.host() ?? "")"
                cookieProperties[.path] = cookie.path

                if let newCookie = HTTPCookie(properties: cookieProperties) {
                    HTTPCookieStorage.shared.setCookie(newCookie)
                }
            }
        }
    }
}
