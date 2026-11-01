import SwiftUI

struct DetailsInfoColumnView<T: View>: View {
    private let title: String
    private let value: String
    private let subtitle: T
    private let hover: String?
    private let valueColor: Color?
    private let url: URL?

    init(_ title: String, _ value: String, _ subtitle: T, valueColor: Color? = nil, hover: String? = nil, url: URL? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.hover = hover
        self.valueColor = valueColor
        self.url = url
    }

    @State private var show: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer()

            if let url {
                Link(destination: url) {
                    VStack(alignment: .center, spacing: 2) {
                        Text(title).font(.body.weight(.medium))

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(value)
                                .font(.system(.title, design: .rounded, weight: .semibold))
                                .viewModifier { view in
                                    if let valueColor {
                                        view.foregroundStyle(valueColor)
                                    } else {
                                        view
                                    }
                                }

                            if let hover, show {
                                Text(verbatim: "(\(hover))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .viewModifier { view in
                            if hover != nil {
                                view.onHover { hover in
                                    withAnimation(.easeInOut) {
                                        show = hover
                                    }
                                }
                            } else {
                                view
                            }
                        }

                        subtitle
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .center, spacing: 2) {
                    Text(title).font(.body.weight(.medium))

                    HStack(alignment: .center, spacing: 2) {
                        Text(value)
                            .font(.system(.title, design: .rounded, weight: .semibold))
                            .viewModifier { view in
                                if let valueColor {
                                    view.foregroundStyle(valueColor)
                                } else {
                                    view
                                }
                            }

                        if let hover, show {
                            Text(verbatim: "(\(hover))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .viewModifier { view in
                        if hover != nil {
                            view.onHover { hover in
                                withAnimation(.easeInOut) {
                                    show = hover
                                }
                            }
                        } else {
                            view
                        }
                    }

                    subtitle
                }
            }

            Spacer()
        }
    }
}
