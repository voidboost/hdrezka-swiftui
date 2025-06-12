import Defaults
import Flow
import SwiftUI

struct CategoriesView: View {
    private let title = String(localized: "key.categories")

    @StateObject private var viewModel = CategoriesViewModel()

    @State private var showBar: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        Group {
            if let error = viewModel.state.error {
                ErrorStateView(error, title) {
                    viewModel.load()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let types = viewModel.state.data {
                if types.isEmpty {
                    EmptyStateView(String(localized: "key.categories.empty"), title) {
                        viewModel.load()
                    }
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
                } else {
                    ScrollView(.vertical) {
                        VStack(spacing: 18) {
                            VStack(alignment: .leading) {
                                Spacer()

                                Text(title)
                                    .font(.largeTitle.weight(.semibold))
                                    .lineLimit(1)

                                Spacer()

                                Divider()
                            }
                            .frame(height: 52)

                            LazyVStack(alignment: .leading, spacing: 18) {
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
                        .padding(.vertical, 52)
                        .padding(.horizontal, 36)
                        .onGeometryChange(for: Bool.self) { geometry in
                            -geometry.frame(in: .named("scroll")).origin.y / 52 >= 1
                        } action: { showBar in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                self.showBar = showBar
                            }
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollIndicators(.never)
                }
            } else {
                LoadingStateView(title)
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
            }
        }
        .navigationBar(title: title, showBar: showBar, navbar: {
            if let types = viewModel.state.data, !types.isEmpty {
                Button {
                    viewModel.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        })
        .task(id: isLoggedIn) {
            switch viewModel.state {
            case .data:
                break
            default:
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

            self.bestGenre = genre
            self.bestYear = year
        }

        @EnvironmentObject private var appState: AppState

        @State private var bestGenre: MovieGenre
        @State private var bestYear: MovieYear

        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 9) {
                    Text(type.name)
                        .font(.system(size: 22, weight: .semibold))

                    Spacer()

                    Button {
                        appState.path.append(.genre(.init(name: type.name, genreId: type.typeId)))
                    } label: {
                        HStack(alignment: .center) {
                            Text("key.see_all")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor)
                        }
                        .highlightOnHover()
                    }
                    .buttonStyle(.plain)
                }

                HFlow(horizontalAlignment: .leading, verticalAlignment: .center, horizontalSpacing: 6, verticalSpacing: 6, distributeItemsEvenly: true) {
                    ForEach(type.genres) { genre in
                        Button {
                            appState.path.append(.genre(genre))
                        } label: {
                            Text(genre.name)
                                .font(.system(size: 13))
                                .frame(height: 28)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .background(.tertiary.opacity(0.05))
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
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
                    .viewModifier { view in
                        if #available(macOS 14, *) {
                            view
                                .buttonStyle(.accessoryBar)
                                .controlSize(.large)
                        } else {
                            view
                        }
                    }
                    .frame(height: 28)
                    .background(.tertiary.opacity(0.05))
                    .clipShape(.rect(cornerRadius: 6))
                    .contentShape(.rect(cornerRadius: 6))
                    .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))

                    Picker("key.categories", selection: $bestYear) {
                        ForEach(type.best.years) { year in
                            Text(year.name)
                                .tag(year)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .viewModifier { view in
                        if #available(macOS 14, *) {
                            view
                                .buttonStyle(.accessoryBar)
                                .controlSize(.large)
                        } else {
                            view
                        }
                    }
                    .frame(height: 28)
                    .background(.tertiary.opacity(0.05))
                    .clipShape(.rect(cornerRadius: 6))
                    .contentShape(.rect(cornerRadius: 6))
                    .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))

                    Button {
                        appState.path.append(.list(.init(name: type.name, listId: bestGenre.genreId + (bestYear.year != 0 ? "\(bestYear.year.description)/" : ""))))
                    } label: {
                        Text("key.go")
                            .font(.system(size: 13))
                            .frame(height: 28)
                            .padding(.horizontal, 16)
                            .background(.tertiary.opacity(0.05))
                            .clipShape(.rect(cornerRadius: 6))
                            .contentShape(.rect(cornerRadius: 6))
                            .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(.tertiary.opacity(0.05))
                .clipShape(.rect(cornerRadius: 6))
                .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
            }
        }
    }
}
