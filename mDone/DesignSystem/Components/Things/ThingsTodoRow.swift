import SwiftUI

/// Presentational to-do row (spec 02 section 2). Reads only its model.
///
/// iOS: title, then a metadata line (notes icon, tags, checklist, deadline).
/// Mac (docs/things-spec/reference/mac-dark-01.png): the checkbox is vertically
/// centred, the title line carries the date pill, the notes icon and the tag
/// pills inline, a second line shows the project name, the selection is a
/// rounded highlight and there is no separator.
struct ThingsTodoRow: View {
    let model: ThingsTodoRowModel
    var isSelected: Bool = false
    var onToggle: (() -> Void)? = nil

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        content
            .opacity(model.isDimmed ? ThingsColorOpacity.somedayDim : 1)
            .animation(ThingsMotion.resolved(ThingsMotion.titleStrike, reduceMotion: reduceMotion), value: model.checkbox)
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        macRow
        #else
        iosRow
        #endif
    }

    // MARK: - Mac

    #if os(macOS)
    private var macRow: some View {
        HStack(alignment: .center, spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            if model.showsTodayStar {
                Image(systemName: ThingsIcons.today)
                    .font(.system(size: ThingsMetrics.Row.starSize))
                    .foregroundStyle(palette[.todayStar])
                    .accessibilityLabel(Text("Today"))
            }
            ThingsCheckbox(state: model.checkbox, action: onToggle, isDashed: model.isSomeday)
            VStack(alignment: .leading, spacing: ThingsMetrics.Row.lineSpacing) {
                macTitleLine
                if let line = model.projectLine, !line.isEmpty {
                    Text(verbatim: line)
                        .font(ThingsTypography.projectLine)
                        .foregroundStyle(palette[.textSecondary])
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if let days = model.deadlineDaysRemaining {
                ThingsDeadlineBadge(daysRemaining: days)
            }
        }
        .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
        .padding(.vertical, ThingsMetrics.Row.verticalPadding)
        .frame(
            minHeight: model.hasProjectLine ? ThingsMetrics.Row.twoLineHeight : ThingsMetrics.Row.minHeight,
            alignment: .leading
        )
        .background(
            RoundedRectangle(cornerRadius: ThingsMetrics.Row.selectionCornerRadius, style: .continuous)
                .fill(isSelected ? palette[.selectionRow] : Color.clear)
        )
    }

    private var macTitleLine: some View {
        HStack(alignment: .center, spacing: ThingsMetrics.Row.trailingItemSpacing) {
            if let pill = model.datePill, !pill.isEmpty {
                Text(verbatim: pill)
                    .font(ThingsTypography.datePill)
                    .foregroundStyle(palette[.textSecondary])
                    .padding(.horizontal, 5)
                    .frame(height: ThingsMetrics.Chip.datePillHeight)
                    .background(
                        RoundedRectangle(cornerRadius: ThingsMetrics.Chip.datePillCornerRadius, style: .continuous)
                            .fill(palette[.bgCalendarBox])
                    )
            }
            if model.isRepeating {
                Image(systemName: ThingsIcons.repeating)
                    .font(.system(size: ThingsMetrics.Row.indicatorIconSize, weight: .semibold))
                    .foregroundStyle(palette[.accent])
                    .accessibilityLabel(Text("Repeating"))
            }
            // The strike line is an overlay rather than `strikethrough` so it can grow
            // over the title and fade in, which a text attribute cannot do.
            Text(verbatim: model.title)
                .font(ThingsTypography.todoTitle)
                .foregroundStyle(model.isFinished ? palette[.textSecondary] : palette[.textPrimary])
                .lineLimit(1)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(palette[.textSecondary])
                        .frame(height: ThingsMetrics.Strike.thickness)
                        .scaleEffect(x: model.isFinished ? 1 : 0, y: 1, anchor: .leading)
                        .opacity(model.isFinished ? 1 : 0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            if model.hasNotes {
                Image(systemName: ThingsIcons.notesDocument)
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
            if !visibleTags.isEmpty {
                HStack(spacing: ThingsMetrics.Spacing.xs) {
                    ForEach(Array(visibleTags.enumerated()), id: \.offset) { item in
                        ThingsTagChip(title: item.element)
                    }
                    if hiddenTagCount > 0 {
                        Text(verbatim: "+\(hiddenTagCount)")
                            .font(ThingsTypography.tagPill)
                            .foregroundStyle(palette[.textSecondary])
                    }
                }
                .padding(.leading, ThingsMetrics.Row.tagLeadingSpacing - ThingsMetrics.Row.trailingItemSpacing)
            }
        }
    }
    #endif

    // MARK: - iOS

    #if !os(macOS)
    private var iosRow: some View {
        HStack(alignment: .top, spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            if model.showsTodayStar {
                Image(systemName: ThingsIcons.today)
                    .font(.system(size: ThingsMetrics.Row.starSize))
                    .foregroundStyle(palette[.todayStar])
                    .frame(height: ThingsMetrics.Checkbox.size)
                    .accessibilityLabel(Text("Today"))
            }
            ThingsCheckbox(state: model.checkbox, action: onToggle, isDashed: model.isSomeday)
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
    #endif

    // MARK: - Shared

    private var visibleTags: [String] {
        Array(model.tags.prefix(ThingsMetrics.Row.maxVisibleTags))
    }

    private var hiddenTagCount: Int {
        max(model.tags.count - ThingsMetrics.Row.maxVisibleTags, 0)
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
                isRepeating: true, showsTodayStar: true, projectLine: "Work"))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(
                id: "3", title: "Call Kate", hasNotes: true, deadlineDaysRemaining: -1, reminderText: "9:00"))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(id: "4", title: "Done item", checkbox: .done))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(id: "5", title: "Canceled item", checkbox: .cancelled))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(id: "6", title: "Someday idea", isDimmed: true, isSomeday: true))
            ThingsDivider()
            ThingsTodoRow(model: ThingsTodoRowModel(id: "7", title: "Selected", checkbox: .inProgress, projectLine: "Perso"), isSelected: true)
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
