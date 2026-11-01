import AVFoundation
import Defaults
import Kingfisher
import Sparkle
import SQLiteData
import SwiftUI

struct SettingsView: View {
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .center, spacing: 10) {
                MirrorSection()

                GeneralSection()

                SnowSection()

                UpdatesSection(updater: updater)
            }
            .padding(25)
            .background(.background)
        }
        .scrollIndicators(.visible, axes: .vertical)
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .frame(minHeight: 400, maxHeight: 500)
    }
}

private struct MirrorSection: View {
    @Default(.mirror) private var mirror

    @Dependency(\.cookiesClient) private var cookiesClient

    @State private var host: String = ""
    @State private var hostValid: Bool?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text("key.mirror")

                Group {
                    if let currentHost = mirror.host() {
                        TextField("key.mirror", text: $host, prompt: Text(currentHost))
                    } else {
                        TextField("key.mirror", text: $host)
                    }
                }
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .autocorrectionDisabled()
                .task(id: host) {
                    withAnimation(.easeInOut) {
                        hostValid = nil
                    }

                    guard !host.isEmpty else { return }

                    try? await Task.sleep(for: .milliseconds(500))

                    guard !Task.isCancelled else { return }

                    withAnimation(.easeInOut) {
                        hostValid = host.isValidHost && host != mirror.host()
                    }
                }

                if !_mirror.isDefaultValue {
                    Button {
                        cookiesClient.setMirror(_mirror.defaultValue)

                        withAnimation(.easeInOut) {
                            hostValid = nil
                        }
                    } label: {
                        Image(systemName: "gobackward")
                    }
                    .buttonStyle(.accessoryBar)
                }
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cardStyle()

            if hostValid == true {
                Button {
                    applyHost()
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
        .onChange(of: mirror) {
            host = ""
        }
    }

    private func applyHost() {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = "/"

        if let newMirror = urlComponents.url {
            cookiesClient.setMirror(newMirror)
        }

        withAnimation(.easeInOut) {
            hostValid = nil
        }
    }
}

private struct GeneralSection: View {
    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.playerFullscreen) private var playerFullscreen
    @Default(.hideMainWindow) private var hideMainWindow
    @Default(.defaultQuality) private var defaultQuality
    @Default(.spatialAudio) private var spatialAudio
    @Default(.theme) private var theme
    @Default(.maxConcurrentDownloads) private var maxConcurrentDownloads
    @Default(.cache) private var cache
    @Default(.mediaControlButtonIsSeeking) private var mediaControlButtonIsSeeking

    @Dependency(\.defaultDatabase) private var database

    @FetchOne(PlayerPosition.count(), animation: .easeInOut) private var playerPositionsCount: Int = 0
    @FetchOne(SelectPosition.count(), animation: .easeInOut) private var selectPositionsCount: Int = 0

    var body: some View {
        SettingsGroup {
            SettingsRow("key.theme") {
                Picker("key.theme", selection: $theme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.localizedKey)
                            .tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Divider()

            SettingsToggle("key.playerFullscreen", isOn: $playerFullscreen)

            Divider()

            SettingsToggle("key.hideMainWindow", isOn: $hideMainWindow)

            Divider()

            SettingsRow("key.spatialAudio") {
                Picker("key.spatialAudio", selection: $spatialAudio) {
                    ForEach(SpatialAudio.allCases) { format in
                        Text(format.localizedKey)
                            .tag(format)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Divider()

            SettingsRow("key.defaultQuality") {
                Picker("key.defaultQuality", selection: $defaultQuality) {
                    ForEach(DefaultQuality.allCases) { quality in
                        Text(quality.localizedKey)
                            .tag(quality)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Divider()

            SettingsRow {
                Text("key.maxConcurrentDownloads-\(maxConcurrentDownloads)")
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(maxConcurrentDownloads)))
                    .animation(.easeInOut, value: maxConcurrentDownloads)
            } content: {
                Slider(value: Binding { Double(maxConcurrentDownloads) } set: { value in maxConcurrentDownloads = Int(value) }, in: 1 ... 10, step: 1) {
                    Text("key.maxConcurrentDownloads-\(maxConcurrentDownloads)")
                } minimumValueLabel: {
                    Text(verbatim: "1")
                } maximumValueLabel: {
                    Text(verbatim: "10")
                }
                .labelsHidden()
                .controlSize(.large)
            }

            Divider()

            SettingsToggle("key.media_control_button_change", isOn: $mediaControlButtonIsSeeking)

            Divider()

            SettingsRow {
                Text("key.playerPositions-\(playerPositionsCount)")
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(playerPositionsCount)))
            } content: {
                Button {
                    Task.detached(priority: .utility) {
                        try? await database.write { db in
                            try PlayerPosition.delete().execute(db)
                        }
                    }
                } label: {
                    trashIcon
                }
                .buttonStyle(.plain)
                .disabled(playerPositionsCount == 0)
            }

            if !isLoggedIn {
                Divider()

                SettingsRow {
                    Text("key.selectPositions-\(selectPositionsCount)")
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(selectPositionsCount)))
                } content: {
                    Button {
                        Task.detached(priority: .utility) {
                            try? await database.write { db in
                                try SelectPosition.delete().execute(db)
                            }
                        }
                    } label: {
                        trashIcon
                    }
                    .buttonStyle(.plain)
                    .disabled(selectPositionsCount == 0)
                }
            }

            Divider()

            SettingsRow("key.cache") {
                Picker("key.cache", selection: $cache) {
                    ForEach(Cache.allCases) { cache in
                        Text(cache.localizedKey)
                            .tag(cache)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .onChange(of: cache) {
                applyCache()
            }
        }
    }

    private var trashIcon: some View {
        Image(systemName: "trash")
            .foregroundStyle(Color.accentColor)
            .bold()
            .imageFill(1)
            .frame(height: 30)
            .contentShape(.rect(cornerRadius: 6))
            .overlay(Color.accentColor, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
    }

    private func applyCache() {
        switch cache {
        case .off:
            ImageCache.default.clearCache()

            ImageCache.default.memoryStorage.config.expiration = .expired
            ImageCache.default.diskStorage.config.expiration = .expired
        case .memory:
            ImageCache.default.clearDiskCache()

            ImageCache.default.memoryStorage.config.expiration = .seconds(300)
            ImageCache.default.diskStorage.config.expiration = .expired
        case .disk:
            ImageCache.default.clearMemoryCache()

            ImageCache.default.memoryStorage.config.expiration = .expired
            ImageCache.default.diskStorage.config.expiration = .days(7)
        case .all:
            ImageCache.default.memoryStorage.config.expiration = .seconds(300)
            ImageCache.default.diskStorage.config.expiration = .days(7)
        }
    }
}

private struct SnowSection: View {
    @Default(.snow) private var snow
    @Default(.forceSnow) private var forceSnow
    @Default(.snowIntensity) private var snowIntensity
    @Default(.snowAccumulates) private var snowAccumulates
    @Default(.snowMelts) private var snowMelts
    @Default(.snowOnSurfaces) private var snowOnSurfaces

    var body: some View {
        SettingsGroup {
            SettingsToggle("key.snow", isOn: $snow)

            let weekOfYear = Calendar.current.component(.weekOfYear, from: .now)

            if snow, weekOfYear > 2, weekOfYear < 51 {
                Divider()

                SettingsToggle("key.forceSnow", isOn: $forceSnow)
            }

            if snow {
                Divider()

                SettingsRow("key.snow.intensity") {
                    Text(snowIntensity.localizedKey)
                        .foregroundStyle(.secondary)

                    Slider(value: Binding { Double(snowIntensity.rawValue) } set: { value in snowIntensity = SnowIntensity(rawValue: Int(value.rounded())) ?? .steady }, in: 0 ... Double(SnowIntensity.allCases.count - 1), step: 1) {
                        Text("key.snow.intensity")
                    }
                    .labelsHidden()
                    .controlSize(.large)
                    .frame(width: 200)
                }

                Divider()

                SettingsToggle("key.snow.accumulates", isOn: $snowAccumulates)

                Divider()

                SettingsToggle("key.snow.melts", isOn: $snowMelts)
                    .disabled(!snowAccumulates)

                Divider()

                SettingsToggle("key.snow.on_surfaces", isOn: $snowOnSurfaces)
            }
        }
    }
}

private struct UpdatesSection: View {
    private let updater: SPUUpdater

    @State private var automaticallyChecksForUpdates: Bool
    @State private var automaticallyDownloadsUpdates: Bool
    @State private var updateCheckInterval: TimeInterval

    init(updater: SPUUpdater) {
        self.updater = updater
        automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates
        updateCheckInterval = updater.updateCheckInterval
    }

    var body: some View {
        SettingsGroup {
            SettingsToggle("key.autoCheckUpdates", isOn: $automaticallyChecksForUpdates)
                .onChange(of: automaticallyChecksForUpdates) {
                    updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
                }

            Divider()

            SettingsToggle("key.autoDownloadUpdates", isOn: $automaticallyDownloadsUpdates)
                .disabled(!automaticallyChecksForUpdates)
                .onChange(of: automaticallyDownloadsUpdates) {
                    updater.automaticallyDownloadsUpdates = automaticallyDownloadsUpdates
                }

            Divider()

            SettingsRow("key.updateCheckInterval") {
                Picker("key.updateCheckInterval", selection: $updateCheckInterval) {
                    ForEach(UpdateInterval.allCases) { interval in
                        Text(interval.localizedKey)
                            .tag(TimeInterval(interval.rawValue))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .disabled(!automaticallyChecksForUpdates)
            .onChange(of: updateCheckInterval) {
                updater.updateCheckInterval = updateCheckInterval
            }
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, 15)
        .cardStyle()
    }
}

private struct SettingsRow<Label: View, Content: View>: View {
    private let label: Label
    private let content: Content

    init(@ViewBuilder label: () -> Label, @ViewBuilder content: () -> Content) {
        self.label = label()
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            label

            Spacer()

            content
        }
        .frame(height: 40)
    }
}

extension SettingsRow where Label == Text {
    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(label: { Text(title) }, content: content)
    }
}

private struct SettingsToggle: View {
    private let title: LocalizedStringKey
    @Binding private var isOn: Bool

    init(_ title: LocalizedStringKey, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        SettingsRow(title) {
            Toggle(title, isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}
