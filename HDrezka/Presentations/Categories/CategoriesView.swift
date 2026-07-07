import SwiftUI

struct CategoriesView: View {
    private let title = String(localized: "key.categories")

    @State private var viewModel = CategoriesViewModel()

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let types = viewModel.state.data, !types.isEmpty {
                    ForEach(types) { type in
                        if let typeView = CategoriesTypeView(type: type) {
                            typeView.equatable()

                            if type != types.last {
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
            if let error = viewModel.state.error {
                ErrorStateView(error) {
                    viewModel.load()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let types = viewModel.state.data, types.isEmpty {
                EmptyStateView(String(localized: "key.categories.empty")) {
                    viewModel.load()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if viewModel.state == .loading {
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
                    viewModel.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.state.data?.isEmpty != false)
            }
        }
        .onAppear {
            switch viewModel.state {
            case .data:
                break
            default:
                viewModel.load()
            }
        }
        .background(.background)
    }
}
