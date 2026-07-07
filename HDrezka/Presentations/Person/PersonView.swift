import Defaults
import SwiftUI

struct PersonView: View {
    private let title: String

    @State private var viewModel: PersonViewModel

    init(person: PersonSimple) {
        title = person.name
        viewModel = PersonViewModel(id: person.personId)
    }

    @Default(.mirror) private var mirror

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let details = viewModel.state.data {
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
            if let error = viewModel.state.error {
                ErrorStateView(error) {
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
                .disabled(viewModel.state.data == nil)
            }

            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: viewModel.id, directoryHint: .notDirectory)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.state.data == nil)
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
