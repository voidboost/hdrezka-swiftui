import ComposableArchitecture
import SwiftUI

struct CategoriesView: View {
    private let title = String(localized: "key.categories")

    @Bindable var store: StoreOf<CategoriesFeature>

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let types = store.types.data, !types.isEmpty {
                    ForEach(types) { type in
                        if let typeView = CategoriesTypeView(type: type) {
                            typeView.equatable()

                            if type.id != types.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 36)
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
            if let error = store.types.error {
                ErrorStateView(error) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let types = store.types.data, types.isEmpty {
                EmptyStateView(String(localized: "key.categories.empty")) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if store.types.isLoading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.send(.reload)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(store.types.data?.isEmpty != false)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .background(.background)
    }
}
