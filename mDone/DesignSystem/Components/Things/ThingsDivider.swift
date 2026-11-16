import SwiftUI

/// Hairline separator. `leadingInset` aligns it on the title text by default.
struct ThingsDivider: View {
    var leadingInset: CGFloat = ThingsMetrics.Row.separatorInset

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Rectangle()
            .fill(ThingsPalette(scheme)[.separator])
            .frame(height: ThingsMetrics.Row.separatorThickness)
            .padding(.leading, leadingInset)
            .accessibilityHidden(true)
    }
}

#Preview("Divider light") {
    VStack(spacing: 24) {
        Text(verbatim: "Above")
        ThingsDivider()
        Text(verbatim: "Below")
        ThingsDivider(leadingInset: 0)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .light))
    .environment(\.colorScheme, .light)
}

#Preview("Divider dark") {
    VStack(spacing: 24) {
        Text(verbatim: "Above")
        ThingsDivider()
        Text(verbatim: "Below")
        ThingsDivider(leadingInset: 0)
    }
    .padding()
    .foregroundStyle(Color.white)
    .background(ThingsTheme.color(.bgPrimary, .dark))
    .environment(\.colorScheme, .dark)
}
