import Defaults
import Flow
import SwiftUI

struct CategoriesView: View {
    @State private var vm = CategoriesViewModel()

    @Default(.isLoggedIn) private var isLoggedIn

    @State private var showBar: Bool = false

    private let title = String(localized: "key.categories")

    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, title) {
                    vm.reload()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let types = vm.state.data {
                if types.isEmpty {
                    EmptyStateView(String(localized: "key.categories.empty"), title) {
                        vm.reload()
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
                            -geometry.frame(in: .scrollView).origin.y / 52 >= 1
                        } action: { showBar in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                self.showBar = showBar
                            }
                        }
                    }
                    .scrollIndicators(.never)
                }
            } else {
                LoadingStateView(title)
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
            }
        }
        .navigationBar(title: title, showBar: showBar, navbar: {
            if let types = vm.state.data, !types.isEmpty {
                Button {
                    vm.reload()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        })
        .load(isLoggedIn) {
            switch vm.state {
            case .data:
                break
            default:
                vm.reload()
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

        @Environment(AppState.self) private var appState

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
                                .foregroundStyle(.accent)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.accent)
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
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 6) {
                    Text("\(type.best.name):")

                    Picker("key.categories", selection: $bestGenre) {
                        ForEach(type.best.genres) { genre in
                            Text(genre.name)
                                .tag(genre)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .buttonStyle(.accessoryBar)
                    .controlSize(.large)
                    .frame(height: 28)
                    .background(.tertiary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                    }

                    Picker("key.categories", selection: $bestYear) {
                        ForEach(type.best.years) { year in
                            Text(year.name)
                                .tag(year)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .buttonStyle(.accessoryBar)
                    .controlSize(.large)
                    .frame(height: 28)
                    .background(.tertiary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                    }

                    Button {
                        appState.path.append(.list(.init(name: type.name, listId: bestGenre.genreId + (bestYear.year != 0 ? "\(bestYear.year.description)/" : ""))))
                    } label: {
                        Text("key.go")
                            .font(.system(size: 13))
                            .frame(height: 28)
                            .padding(.horizontal, 16)
                            .background(.tertiary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .contentShape(RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(.tertiary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.secondary.opacity(0.2), lineWidth: 1)
                }
            }
        }
    }
}
