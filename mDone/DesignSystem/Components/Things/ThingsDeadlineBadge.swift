import SwiftUI

/// Flag and remaining days ("5 days left", "Today", "2 days ago").
/// The caller computes `daysRemaining` (positive ahead, 0 today, negative past).
struct ThingsDeadlineBadge: View {
    let daysRemaining: Int
    /// Replaces the generated wording when set (already localized by the caller).
    var customText: String? = nil

    @Environment(\.colorScheme) private var scheme

    private var isUrgent: Bool { daysRemaining <= ThingsMetrics.Deadline.urgentThresholdDays }

    private var label: Text {
        if let customText = customText { return Text(verbatim: customText) }
        if daysRemaining == 0 { return Text("Today") }
        if daysRemaining == 1 { return Text("1 day left") }
        if daysRemaining > 1 { return Text("\(daysRemaining) days left") }
        let ago = -daysRemaining
        if ago == 1 { return Text("1 day ago") }
        return Text("\(ago) days ago")
    }

    /// The flag and the text always share one colour: the secondary grey while the
    /// deadline is ahead, red when it is today or past (spec 06 section 6).
    private var tint: ThingsColorToken { isUrgent ? .deadlineFlame : .textSecondary }

    var body: some View {
        let palette = ThingsPalette(scheme)
        HStack(spacing: ThingsMetrics.Spacing.xs) {
            Image(systemName: ThingsIcons.deadlineFlag)
                .font(.system(size: ThingsMetrics.Row.indicatorIconSize))
                .foregroundStyle(palette[tint])
            label
                .font(ThingsTypography.deadline)
                .fontWeight(daysRemaining < 0 ? .semibold : .regular)
                .foregroundStyle(palette[tint])
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Deadline light") {
    VStack(alignment: .leading, spacing: 8) {
        ThingsDeadlineBadge(daysRemaining: 5)
        ThingsDeadlineBadge(daysRemaining: 1)
        ThingsDeadlineBadge(daysRemaining: 0)
        ThingsDeadlineBadge(daysRemaining: -2)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .light))
    .environment(\.colorScheme, .light)
}

#Preview("Deadline dark") {
    VStack(alignment: .leading, spacing: 8) {
        ThingsDeadlineBadge(daysRemaining: 5)
        ThingsDeadlineBadge(daysRemaining: 1)
        ThingsDeadlineBadge(daysRemaining: 0)
        ThingsDeadlineBadge(daysRemaining: -2)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .dark))
    .environment(\.colorScheme, .dark)
}
