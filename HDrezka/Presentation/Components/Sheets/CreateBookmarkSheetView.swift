import Combine
import FactoryKit
import SwiftUI

struct CreateBookmarkSheetView: View {
    @Injected(\.createBookmarksCategoryUseCase) private var createBookmarksCategoryUseCase

    @State private var subscriptions: Set<AnyCancellable> = []

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var state: EmptyState = .data

    private enum FocusedField {
        case name
    }

    @FocusState private var focusedField: FocusedField?

    var body: some View {
        Group {
            switch state {
            case .data:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "bookmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

                        Text("key.create.label")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.create.description")
                            .font(.title3)
                            .lineLimit(2, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        VStack(spacing: 2.5) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("key.name")

                                TextField("key.name", text: $name, prompt: Text(String(localized: "key.name").lowercased()))
                                    .textFieldStyle(.plain)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .name)
                                    .onSubmit {
                                        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            withAnimation(.easeInOut) {
                                                state = .loading
                                            }

                                            createBookmarksCategoryUseCase(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                                                .receive(on: DispatchQueue.main)
                                                .sink { completion in
                                                    guard case let .failure(error) = completion else { return }

                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                        withAnimation(.easeInOut) {
                                                            state = .error(error as NSError)
                                                        }
                                                    }
                                                } receiveValue: { _ in
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                        dismiss()
                                                    }
                                                }
                                                .store(in: &subscriptions)
                                        }
                                    }
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.tertiary, lineWidth: 1)
                        }
                    }

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            withAnimation(.easeInOut) {
                                state = .loading
                            }

                            createBookmarksCategoryUseCase(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                                .receive(on: DispatchQueue.main)
                                .sink { completion in
                                    guard case let .failure(error) = completion else { return }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation(.easeInOut) {
                                            state = .error(error as NSError)
                                        }
                                    }
                                } receiveValue: { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        dismiss()
                                    }
                                }
                                .store(in: &subscriptions)
                        } label: {
                            Text("key.create")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .accent : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .animation(.easeInOut, value: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button {
                            dismiss()
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background(.quinary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .task {
                    focusedField = .name
                }
            case .loading:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "bookmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

                        Text("key.create.enter")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.request.wait")
                            .font(.title3)
                            .lineLimit(1, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            subscriptions.forEach { $0.cancel() }
                            subscriptions.removeAll()

                            withAnimation(.easeInOut) {
                                state = .data
                            }
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background(.quinary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .error:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "bookmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

                        Text("key.ops")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.name.error")
                            .font(.title3)
                            .lineLimit(1, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            withAnimation(.easeInOut) {
                                state = .data
                            }
                        } label: {
                            Text("key.retry")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background(.quinary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 520)
    }
}
