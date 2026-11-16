import SwiftUI

/// The live preview under a to-do field: what the typed line will become, as
/// Things-like chips (When, deadline, reminder, repeat, project, tags,
/// priority, estimate). Shows nothing when the "Smart parsing" preference is
/// off or the text names no field, so a plain title stays a plain title.
struct ThingsNaturalLanguagePreview: View {
    let text: String
    let appState: AppState

    @Environment(\.colorScheme) private var scheme

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        let mapper = ThingsNaturalLanguage.current(appState: appState)
        let plan = mapper.plan(for: text)
        let chips = mapper.isEnabled && plan.hasEffect
            ? plan.chips(now: mapper.now, calendar: mapper.calendar, locale: mapper.locale)
            : []
        return Group {
            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ThingsMetrics.Spacing.xs) {
                        ForEach(chips) { chip in
                            chipView(chip, plan: plan)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(verbatim: chips.map { $0.text }.joined(separator: ", ")))
            }
        }
    }

    private func chipView(_ chip: ThingsNaturalLanguageChip, plan: ThingsNaturalLanguagePlan) -> some View {
        let style = style(for: chip, plan: plan)
        return HStack(spacing: ThingsMetrics.Spacing.xs) {
            if let symbol = style.symbol {
                Image(systemName: symbol)
                    .font(ThingsTypography.tagPill)
                    .foregroundStyle(palette[style.tint])
            }
            Text(verbatim: chip.text)
                .font(ThingsTypography.tagPill)
                .foregroundStyle(chip.kind == .tag ? palette[.tagPillText] : palette[.textPrimary])
                .lineLimit(1)
        }
        .padding(.horizontal, ThingsMetrics.Chip.horizontalPadding)
        .padding(.vertical, ThingsMetrics.Chip.verticalPadding)
        .background(Capsule().fill(palette[.tagPillBackground]))
    }

    private func style(
        for chip: ThingsNaturalLanguageChip,
        plan: ThingsNaturalLanguagePlan
    ) -> (symbol: String?, tint: ThingsColorToken) {
        switch chip.kind {
        case .when:
            switch plan.when ?? ThingsWhen.none {
            case .today: return (ThingsIcons.today, .todayStar)
            case .thisEvening: return (ThingsIcons.evening, .eveningMoon)
            case .someday: return (ThingsIcons.someday, .somedayTan)
            case .date: return (ThingsIcons.upcoming, .upcomingRed)
            case .none: return (nil, .textSecondary)
            }
        case .reminder: return (ThingsIcons.reminder, .textSecondary)
        case .deadline: return (ThingsIcons.deadlineFlag, .deadlineFlame)
        case .repeating: return (ThingsIcons.repeating, .textSecondary)
        case .project: return (ThingsIcons.project, .accent)
        case .tag: return (ThingsIcons.tag, .textSecondary)
        case .priority: return ("exclamationmark", .deadlineFlame)
        case .estimate: return ("timer", .textSecondary)
        }
    }
}
