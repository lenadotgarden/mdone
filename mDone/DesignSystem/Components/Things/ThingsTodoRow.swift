import SwiftUI

/// Presentational to-do row (spec 02 section 2). Reads only its model.
struct ThingsTodoRow: View {
    let model: ThingsTodoRowModel
    var isSelected: Bool = false
    var onToggle: (() -> Void)? = nil

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        HStack(alignment: .top, spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            if model.showsTodayStar {
                Image(systemName: ThingsIcons.today)
                    .font(.system(size: ThingsMetrics.Row.starSize))
                    .foregroundStyle(palette[.todayStar])
                    .frame(height: ThingsMetrics.Checkbox.size)
                    .accessibilityLabel(Text("Today"))
            }
            ThingsCheckbox(state: model.checkbox, action: onToggle)
            VStack(alignment: .leading, spacing: ThingsMetrics.Row.lineSpacing) {
                titleLine
                if let preview = model.notesPreview, !preview.isEmpty {
                    Text(verbatim: preview)
                        .font(ThingsTypography.notes)
                        .foregroundStyle(palette[.textSecondary])
                        .lineLimit(1)
                }
                if hasMetadata { metadataLine }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
        .padding(.vertical, ThingsMetrics.Row.verticalPadding)
        .frame(minHeight: ThingsMetrics.Row.minHeight, alignment: .topLeading)
        .background(isSelected ? palette[.selectionRow] : Color.clear)
        .opacity(model.isDimmed ? ThingsColorOpacity.somedayDim : 1)
        .animation(ThingsMotion.resolved(ThingsMotion.titleStrike, reduceMotion: reduceMotion), value: model.checkbox)
    }

    private var titleLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: ThingsMetrics.Spacing.xs) {
            if model.isRepeating {
                Image(systemName: ThingsIcons.repeating)
                    .font(.system(size: ThingsMetrics.Row.indicatorIconSize, weight: .semibold))
                    .foregroundStyle(palette[.accent])
                    .accessibilityLabel(Text("Repeating"))
            }
            Text(verbatim: model.title)
                .font(ThingsTypography.todoTitle)
                .foregroundStyle(model.isFinished ? palette[.textSecondary] : palette[.textPrimary])
                .strikethrough(model.isFinished)
                .lineLimit(3)
        }
    }

    private var hasMetadata: Bool {
        model.hasNotes && (model.notesPreview ?? "").isEmpty
            || !model.tags.isEmpty
            || model.checklistLabel != nil
            || model.deadlineDaysRemaining != nil
            || model.reminderText != nil
    }

    private var visibleTags: [String] {
        Array(model.tags.prefix(ThingsMetrics.Row.maxVisibleTags))
    }

    private var hiddenTagCount: Int {
        max(model.tags.count - ThingsMetrics.Row.maxVisibleTags, 0)
    }

    private var metadataLine: some View {
        HStack(spacing: ThingsMetrics.Spacing.s) {
            if model.hasNotes && (model.notesPreview ?? "").isEmpty {
                Image(systemName: ThingsIcons.notes)
                    .font(.system(size: ThingsMetrics.Row.indicatorIconSize))
                    .foregroundStyle(palette[.textSecondary])
                    .accessibilityLabel(Text("Has notes"))
            }
            if let checklist = model.checklistLabel {
                HStack(spacing: ThingsMetrics.Spacing.xxs) {
                    Image(systemName: ThingsIcons.checklist)
                        .font(.system(size: ThingsMetrics.Row.indicatorIconSize))
                    Text(verbatim: checklist).font(ThingsTypography.counter)
                }
                .foregroundStyle(palette[.textSecondary])
                .accessibilityElement(children: .combine)
            }
            ForEach(Array(visibleTags.enumerated()), id: \.offset) { item in
                ThingsTagChip(title: item.element)
            }
            if hiddenTagCount > 0 {
                Text(verbatim: "+\(hiddenTagCount)")
                    .font(ThingsTypography.tagPill)
                    .foregroundStyle(palette[.textSecondary])
            }
            Spacer(minLength: ThingsMetrics.Spacing.xs)
            if let reminder = model.reminderText {
                Text(verbatim: reminder)
                    .font(ThingsTypography.deadline)
                    .foregroundStyle(palette[.textSecondary])
            }
            if let days = model.deadlineDaysRemaining {
                ThingsDeadlineBadge(daysRemaining: days)
            }
        }
    }
}

private struct ThingsTodoRowSamples: View {
    var body: some View {
        VStack(spacing: 0) {
            ThingsTodoRow(model: ThingsTodoRowModel(id: "1", title: "Buy bread"))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(
                id: "2", title: "Write the quarterly report", notesPreview: "Numbers from finance first",
                tags: ["Office", "Important"], deadlineDaysRemaining: 3, checklistLabel: "2/5",
                isRepeating: true, showsTodayStar: true))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(
                id: "3", title: "Call Kate", hasNotes: true, deadlineDaysRemaining: -1, reminderText: "9:00"))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(id: "4", title: "Done item", checkbox: .done))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(id: "5", title: "Canceled item", checkbox: .cancelled))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(id: "6", title: "Someday idea", isDimmed: true))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(id: "7", title: "Selected", checkbox: .inProgress), isSelected: true)
        }
    }
}

#Preview("Todo row light") {
    ThingsTodoRowSamples()
        .background(ThingsTheme.color(.bgPrimary, .light))
        .environment(\.colorScheme, .light)
}

#Preview("Todo row dark") {
    ThingsTodoRowSamples()
        .background(ThingsTheme.color(.bgPrimary, .dark))
        .environment(\.colorScheme, .dark)
}
