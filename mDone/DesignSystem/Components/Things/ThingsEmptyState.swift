import SwiftUI

/// Centered placeholder for an empty list. Wording is the caller's (spec 06 holds the texts).
/// The captures show no empty list, so the Mac look is [PROPOSAL]: a small tinted icon,
/// a 14 pt secondary title and a 13 pt placeholder-grey message, as quiet as the rest of the list.
struct ThingsEmptyState: View {
    let symbolName: String
    let title: String
    var message: String? = nil
    var tint: ThingsColorToken = .textSecondary

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        VStack(spacing: ThingsMetrics.Empty.spacing) {
            Image(systemName: symbolName)
                .font(.system(size: ThingsMetrics.Empty.iconSize, weight: .light))
                .foregroundStyle(palette[tint].opacity(ThingsColorOpacity.somedayDim))
                .accessibilityHidden(true)
            Text(verbatim: title)
                .font(ThingsTypography.emptyTitle)
                .foregroundStyle(palette[.textSecondary])
                .multilineTextAlignment(.center)
            if let message = message {
                Text(verbatim: message)
                    .font(ThingsTypography.emptyMessage)
                    .foregroundStyle(palette[.textPlaceholder])
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: ThingsMetrics.Empty.maxTextWidth)
        .padding(ThingsMetrics.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Empty state light") {
    ThingsEmptyState(symbolName: ThingsIcons.today,
                     title: "Nothing for today",
                     message: "Enjoy the free time.",
                     tint: .todayStar)
        .background(ThingsTheme.color(.bgPrimary, .light))
        .environment(\.colorScheme, .light)
}

#Preview("Empty state dark") {
    ThingsEmptyState(symbolName: ThingsIcons.inbox,
                     title: "Inbox is empty",
                     message: "New to-dos land here.",
                     tint: .accent)
        .background(ThingsTheme.color(.bgPrimary, .dark))
        .environment(\.colorScheme, .dark)
}
