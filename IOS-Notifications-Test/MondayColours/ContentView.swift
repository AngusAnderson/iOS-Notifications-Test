import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    @State private var status = "Sunday reminders at 18:00 · UK time"
    @State private var isWorking = false

    private var upcomingEntries: [MondayEntry] {
        let today = ColourSchedule.calendar.startOfDay(for: Date())

        return ColourSchedule.entries.filter {
            $0.date >= today
        }
    }

    private var nextEntry: MondayEntry? {
        upcomingEntries.first
    }

    private var accent: Color {
        ColourPalette.colour(
            for: nextEntry?.colours.first ?? "Blue"
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        heading

                        if let entry = nextEntry {
                            nextMondayCard(entry)

                            upcomingSection(
                                Array(upcomingEntries.dropFirst())
                            )
                        } else {
                            emptyState
                        }

                        Text("Calendar ends on 25 October 2027")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                reminderControls
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
        }
        .tint(accent)
    }

    // MARK: - Background

    private var background: some View {
        ZStack(alignment: .topTrailing) {
            Color(uiColor: .systemGroupedBackground)

            if !reduceTransparency {
                Circle()
                    .fill(accent.opacity(0.20))
                    .frame(width: 300, height: 300)
                    .blur(radius: 75)
                    .offset(x: 100, y: -70)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Heading

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Monday Colours")
                .font(.largeTitle.bold())

            Text("A little reminder for the week ahead.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Main colour card

    private func nextMondayCard(
        _ entry: MondayEntry
    ) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text(isToday(entry.date) ? "TODAY" : "NEXT MONDAY")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "calendar")
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)
            }

            Text(ColourSchedule.dateLabel(entry.date))
                .font(.title2.bold())

            HStack(spacing: 12) {
                ForEach(entry.colours, id: \.self) { name in
                    colourTile(name)
                }
            }

            Label(
                "Sunday reminders at 18:00",
                systemImage: "bell"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
            .strokeBorder(
                accent.opacity(0.15),
                lineWidth: 1
            )
        }
    }

    private func colourTile(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(ColourPalette.colour(for: name).gradient)
            .frame(height: 110)
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .strokeBorder(
                    Color.primary.opacity(0.08),
                    lineWidth: 1
                )
            }
            .accessibilityHidden(true)

            Text(name)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Upcoming Mondays

    private func upcomingSection(
        _ entries: [MondayEntry]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if !entries.isEmpty {
                Text("Coming up")
                    .font(.title3.bold())

                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        upcomingRow(entry)

                        if entry.id != entries.last?.id {
                            Divider()
                                .padding(.leading, 18)
                        }
                    }
                }
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(
                        cornerRadius: 24,
                        style: .continuous
                    )
                )
            }
        }
    }

    private func upcomingRow(
        _ entry: MondayEntry
    ) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(ColourSchedule.dateLabel(entry.date))
                    .font(.subheadline.weight(.semibold))

                Text(entry.colourDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                ForEach(entry.colours, id: \.self) { name in
                    Circle()
                        .fill(ColourPalette.colour(for: name))
                        .frame(width: 18, height: 18)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    Color.primary.opacity(0.10),
                                    lineWidth: 1
                                )
                        }
                }
            }
            .accessibilityHidden(true)
        }
        .padding(18)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Reminder controls

    private var reminderControls: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.badge")
                    .font(.title3)
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sunday reminders")
                        .font(.subheadline.bold())

                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)

                if isWorking {
                    ProgressView()
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    enableButton
                }

                VStack(spacing: 10) {
                    enableButton
                    testButton
                }
            }
        }
        .padding(18)
        .modifier(AdaptiveGlassPanel())
    }

    private var enableButton: some View {
        Button(action: enableReminders) {
            Label(
                "Enable reminders",
                systemImage: "bell.fill"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .disabled(isWorking)
    }

    private var testButton: some View {
        Button(action: sendTest) {
            Label(
                "Test",
                systemImage: "paperplane"
            )
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 32)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .disabled(isWorking)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("You’re all caught up")
                .font(.title2.bold())

            Text("Add the next calendar to schedule more reminders.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // MARK: - Helpers

    private func isToday(_ date: Date) -> Bool {
        ColourSchedule.calendar.isDate(
            date,
            inSameDayAs: Date()
        )
    }

    // MARK: - Notification actions

    @MainActor
    private func enableReminders() {
        isWorking = true

        Task {
            defer {
                isWorking = false
            }

            do {
                let count = try await ColourNotifications.schedule()

                if count > 0 {
                    status = """
                    \(count) reminders scheduled · Sundays at 18:00
                    """
                } else {
                    status = "No future reminders remain in this calendar."
                }
            } catch {
                status = error.localizedDescription
            }
        }
    }

    @MainActor
    private func sendTest() {
        isWorking = true

        Task {
            defer {
                isWorking = false
            }

            do {
                try await ColourNotifications.sendTest()

                status = "Test in 10 seconds. Go to the Home Screen."
            } catch {
                status = error.localizedDescription
            }
        }
    }
}

// MARK: - Liquid Glass and fallback

private struct AdaptiveGlassPanel: ViewModifier {
    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    private let shape = RoundedRectangle(
        cornerRadius: 28,
        style: .continuous
    )

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: shape
                )
                .overlay {
                    shape.strokeBorder(
                        Color.primary.opacity(0.12),
                        lineWidth: 1
                    )
                }
        } else if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(
                    .regularMaterial,
                    in: shape
                )
                .overlay {
                    shape.strokeBorder(
                        Color.primary.opacity(0.10),
                        lineWidth: 1
                    )
                }
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 18,
                    y: 8
                )
        }
    }
}

// MARK: - Calendar colours

private enum ColourPalette {
    static func colour(for name: String) -> Color {
        switch name.lowercased() {
        case "green":
            return Color(
                red: 0.18,
                green: 0.58,
                blue: 0.32
            )

        case "blue":
            return Color(
                red: 0.22,
                green: 0.46,
                blue: 0.78
            )

        case "black", "grey", "gray":
            return Color(
                red: 0.21,
                green: 0.24,
                blue: 0.26
            )

        case "brown":
            return Color(
                red: 0.53,
                green: 0.35,
                blue: 0.23
            )

        default:
            return .accentColor
        }
    }
}
