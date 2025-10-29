import FirebaseAnalytics
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
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)

                Text("key.schedule")
                    .font(.largeTitle.weight(.semibold))
            }

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(schedule) { sch in
                        CustomSection(group: sch, isExpanded: schedule.firstIndex(of: sch) == 0)

                        if sch != schedule.last {
                            Divider()
                        }
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
                    .contentShape(.rect(cornerRadius: 6))
                    .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .frame(width: 520, height: 520)
        .analyticsScreen(name: "ScheduleSheet", extraParameters: ["schedule": schedule])
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
                        .font(.title3.bold())

                    Spacer()
                }

                if isExpanded {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(group.items) { item in
                            HStack(alignment: .center) {
                                VStack(alignment: .leading) {
                                    Text(item.russianEpisodeName)
                                        .font(.body)
                                        .lineLimit(1)

                                    if let originalEpisodeName = item.originalEpisodeName {
                                        Text(originalEpisodeName)
                                            .font(.body)
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text(item.releaseDate).font(.body).foregroundStyle(.secondary)

                                    Text(item.title).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)

                            if item != group.items.last {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .background(.quinary, in: .rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut) {
                    isExpanded.toggle()
                }
            }
        }
    }
}
