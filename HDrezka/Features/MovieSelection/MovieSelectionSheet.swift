import ComposableArchitecture
import Dependencies
import SwiftUI

struct MovieSelectionSheet<Actions: View>: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>

    private let icon: String
    private let description: LocalizedStringKey
    private let showsSubtitles: Bool
    private let actions: Actions

    init(store: StoreOf<MovieSelectionFeature>, icon: String, description: LocalizedStringKey, showsSubtitles: Bool, @ViewBuilder actions: () -> Actions) {
        self.store = store
        self.icon = icon
        self.description = description
        self.showsSubtitles = showsSubtitles
        self.actions = actions()
    }

    private var details: MovieDetailed? { store.details }
    private var error: (any Error)? { store.error?.base }

    @Environment(\.dismiss) private var dismiss

    @Dependency(\.appRouter) private var appRouter

    @State private var isLoginPresented: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(alignment: .center, spacing: 5) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)

                Text("key.before_starting")
                    .font(.largeTitle.weight(.semibold))

                Text(description)
                    .font(.title3)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
            }

            selection

            VStack(alignment: .center, spacing: 10) {
                actions

                Button {
                    dismiss()
                } label: {
                    Text("key.cancel")
                        .frame(width: 250, height: 30)
                        .contentShape(.rect(cornerRadius: 6))
                        .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .alert("key.ops", isPresented: $store.isErrorPresented) {
            if let hdrezkaError = error as? HDrezkaError, case .loginRequired = hdrezkaError {
                Button(role: .destructive) {
                    dismiss()

                    appRouter.present(.signIn)
                } label: {
                    Text("key.sign_in")
                }
            }

            Button(role: .cancel) {
                dismiss()
            } label: {
                Text("key.ok")
            }
        } message: {
            if let error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .confirmationDialog("key.sign_in.label", isPresented: $isLoginPresented) {
            Button {
                dismiss()

                appRouter.present(.signIn)
            } label: {
                Text("key.sign_in")
            }
        } message: {
            Text("key.sign_in.access")
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 520)
        .onAppear {
            store.send(.onAppear)
        }
    }

    @ViewBuilder
    private var selection: some View {
        if let details {
            let acting = details.voiceActing ?? []
            let hasNamedActing = acting.contains { !$0.name.isEmpty }

            VStack(spacing: 18) {
                if details.series != nil || hasNamedActing {
                    VStack(spacing: 2.5) {
                        if hasNamedActing {
                            ActingPicker(store: store, acting: acting, rating: details.voiceActingRating ?? [])
                                .padding(.vertical, 10)
                        }

                        if details.series != nil, store.selectedActing != nil {
                            if hasNamedActing {
                                Divider()
                            }

                            SeasonPicker(store: store)
                                .padding(.vertical, 10)

                            Divider()

                            EpisodePicker(store: store)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .cardStyle()
                }

                if (details.series == nil && store.selectedActing != nil) || store.selectedEpisode != nil {
                    QualityPicker(store: store, isLoginPresented: $isLoginPresented)
                        .padding(15)
                        .cardStyle()
                }

                if showsSubtitles, let movie = store.movie, !movie.subtitles.isEmpty {
                    SubtitlesPicker(store: store, subtitles: movie.subtitles)
                        .padding(15)
                        .cardStyle()
                }
            }
        } else {
            ProgressView()
        }
    }
}

struct MovieSelectionActionButton: View {
    private let title: LocalizedStringKey
    private let isActive: Bool
    private let action: () -> Void

    init(_ title: LocalizedStringKey, isActive: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(width: 250, height: 30)
                .foregroundStyle(.white)
                .contentShape(.rect(cornerRadius: 6))
                .background(isActive ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(!isActive)
    }
}
