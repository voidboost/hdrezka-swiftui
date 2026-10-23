import ComposableArchitecture
import Defaults
import SwiftUI

struct PersonView: View {
    let store: StoreOf<PersonFeature>

    @Default(.mirror) private var mirror

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let details = store.details.data {
                    PersonDetailsView(details: details)
                }
            }
            .padding(.vertical, 18)
        }
        .scrollIndicators(.visible, axes: .vertical)
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .overlay {
            if let error = store.details.error {
                ErrorStateView(error) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if store.details.isLoading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.send(.reload)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(store.details.data == nil)
            }

            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: store.id, directoryHint: .notDirectory)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(store.details.data == nil)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .background(.background)
    }
}
