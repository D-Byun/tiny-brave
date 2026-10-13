import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.palette) private var palette
    @AppStorage(AppClock.offsetKey) private var dayOffset = 0
    @Query(sort: \Completion.date) private var completions: [Completion]
    @State private var month: Date
    @State private var selected: Date
    private let store = ChallengeStore.shared
    private let calendar = Calendar.current

    init() {
        let today = AppClock.now
        _month = State(initialValue: today)
        _selected = State(initialValue: today)
    }

    private var today: Date { AppClock.now(offsetDays: dayOffset) }
    private var doneDays: Set<Date> { Set(completions.map { calendar.startOfDay(for: $0.date) }) }
    private var selectedCompletions: [Completion] {
        completions.filter { calendar.isDate($0.date, inSameDayAs: selected) }
    }

    /// Leading nils pad the first week so days line up under their weekday.
    private var cells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let dayCount = calendar.range(of: .day, in: .month, for: month)?.count
        else { return [] }
        let offset = (calendar.component(.weekday, from: interval.start) - calendar.firstWeekday + 7) % 7
        let days: [Date?] = (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
        return Array(repeating: nil, count: offset) + days
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                grid
                detail
            }
            .padding(20)
        }
        .screenBackground()
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(Theme.font(22, relativeTo: .title2))
                .accessibilityIdentifier("calendarMonth")
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next month")
        }
        .buttonStyle(.plain)
    }

    private var grid: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(Theme.font(13, relativeTo: .footnote))
                        .opacity(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    if let date { dayCell(date) } else { Color.clear.frame(height: 44) }
                }
            }
        }
        .padding(10)
        .roughCard()
    }

    private func dayCell(_ date: Date) -> some View {
        let done = doneDays.contains(calendar.startOfDay(for: date))
        let isSelected = calendar.isDate(date, inSameDayAs: selected)
        let isToday = calendar.isDate(date, inSameDayAs: today)
        let count = completions.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
        return Button { selected = date } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(Theme.font(16, relativeTo: .body))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Circle().fill(done ? palette.sun : Color.clear).padding(2))
                .overlay(Circle().strokeBorder(palette.ink, lineWidth: isSelected ? 3 : (isToday ? 1.5 : 0)).padding(2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(.dateTime.month(.wide).day()) + (done ? ", \(count) brave thing\(count == 1 ? "" : "s") done" : ", nothing done"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selected.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                .font(Theme.font(15, relativeTo: .subheadline))
                .tracking(1)
                .accessibilityIdentifier("calendarSelectedDay")
            if selectedCompletions.isEmpty {
                Text("No brave thing this day.")
                    .font(.system(.footnote, design: .rounded))
                    .opacity(0.7)
                    .accessibilityIdentifier("calendarEmpty")
            } else {
                ForEach(selectedCompletions) { completion in taskRow(completion) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func taskRow(_ completion: Completion) -> some View {
        let challenge = store.challenge(id: completion.challengeID)
        return HStack(spacing: 10) {
            if let challenge {
                Text(challenge.level.symbol)
                    .font(.system(size: 14))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(challenge.level.color(in: palette)))
                    .overlay(Circle().stroke(palette.ink, lineWidth: 2.5))
            }
            VStack(alignment: .leading, spacing: 2) {
                if let challenge {
                    Text(challenge.category.title.uppercased())
                        .font(.system(.caption2, design: .rounded))
                        .tracking(1)
                        .opacity(0.55)
                }
                Text(challenge?.text ?? "A brave thing")
                    .font(Theme.font(16, relativeTo: .callout))
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 4)
            if let felt = completion.awkwardness, (0..<3).contains(felt) {
                Text(["😌", "😬", "🫠"][felt]).font(.system(size: 22))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .roughCard(fill: palette.sunSoft)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("calendarTask")
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: month) { month = next }
    }
}
