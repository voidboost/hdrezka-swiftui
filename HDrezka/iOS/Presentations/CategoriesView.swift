import Defaults
import Flow
import SwiftUI

struct CategoriesView: View {
    private let title = String(localized: "key.categories")

    @State private var viewModel = CategoriesViewModel()

    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let types = viewModel.state.data, !types.isEmpty {
                    ForEach(types) { type in
                        if let typeView = TypeView(type: type) {
                            typeView

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
            if #available(iOS 26, *) {
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
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            switch viewModel.state {
            case .data:
                break
            default:
                viewModel.load()
            }
        }
        .refreshable {
            if viewModel.state.data?.isEmpty == false {
                viewModel.load()
            }
        }
        .background(.background)
    }

    private struct TypeView: View {
        private let type: MovieType

        init?(type: MovieType) {
            self.type = type

            guard let genre = type.best.genres.first, let year = type.best.years.first else { return nil }

            bestGenre = genre
            bestYear = year
        }

        @State private var bestGenre: MovieGenre
        @State private var bestYear: MovieYear

        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 9) {
                    Text(type.name)
                        .font(.system(.title, weight: .semibold))

                    Spacer()

                    NavigationLink(value: Destinations.genre(.init(name: type.name, genreId: type.typeId))) {
                        HStack(alignment: .center) {
                            Text("key.see_all")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentColor)

                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                HFlow(horizontalAlignment: .leading, verticalAlignment: .center, horizontalSpacing: 6, verticalSpacing: 6, distributeItemsEvenly: true) {
                    ForEach(type.genres) { genre in
                        NavigationLink(value: Destinations.genre(genre)) {
                            Text(genre.name)
                                .font(.body)
                                .frame(height: 28)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(.tertiary.opacity(0.05), in: .rect(cornerRadius: 6))
                                .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 6) {
                    Text(verbatim: "\(type.best.name):")

                    Picker("key.categories", selection: $bestGenre) {
                        ForEach(type.best.genres) { genre in
                            Text(genre.name)
                                .tag(genre)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)

                    Picker("key.categories", selection: $bestYear) {
                        ForEach(type.best.years) { year in
                            Text(year.name)
                                .tag(year)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)

                    NavigationLink(value: Destinations.list(.init(name: type.name, listId: bestGenre.genreId + (bestYear.year != 0 ? "\(bestYear.year)/" : "")))) {
                        Text("key.go")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(.tertiary.opacity(0.05), in: .rect(cornerRadius: 6))
                .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
            }
        }
    }
}
