import SwiftUI

struct ScheduleSheetView: View {
    private let schedule: [SeriesScheduleGroup]

    @Environment(\.dismiss) private var dismiss

    init(schedule: [SeriesScheduleGroup]) {
        self.schedule = schedule
    }

    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(spacing: 5) {
                Image(systemName: "list.and.film")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)

                Text("key.schedule")
                    .font(.largeTitle.weight(.semibold))
            }

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(schedule) { sch in
                        CustomSection(group: sch, isExpanded: schedule.firstIndex(of: sch) == 0)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.never)

            Button {
                dismiss()
            } label: {
                Text("key.done")
                    .frame(width: 250, height: 30)
                    .background(.quinary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .frame(width: 520, height: 520)
    }

    private struct CustomSection: View {
        private let group: SeriesScheduleGroup

        @State private var isExpanded: Bool

        init(group: SeriesScheduleGroup, isExpanded: Bool = false) {
            self.group = group
            self.isExpanded = isExpanded
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(group.name, systemImage: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 15).bold())
                        .labelStyle(CenterIcon())

                    Spacer()
                }

                if isExpanded {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(group.items) { item in
                            HStack(alignment: .center) {
                                VStack(alignment: .leading) {
                                    Text(item.russianEpisodeName)
                                        .font(.system(size: 13))
                                        .lineLimit(1)

                                    if let originalEpisodeName = item.originalEpisodeName {
                                        Text(originalEpisodeName)
                                            .font(.system(size: 13))
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text(item.releaseDate).font(.system(size: 13)).foregroundStyle(.secondary)

                                    Text(item.title).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)

                            if item != group.items.last {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .background(.quinary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary, lineWidth: 1)
                    }
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut) {
                    isExpanded.toggle()
                }
            }
        }
    }

    private struct CenterIcon: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .center) {
                configuration.icon
                configuration.title
            }
        }
    }
}
