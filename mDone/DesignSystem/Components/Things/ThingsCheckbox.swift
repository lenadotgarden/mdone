import SwiftUI

/// State of a to-do checkbox (spec 01 section 2.4).
enum ThingsCheckboxState: Equatable {
    case open
    case inProgress
    case done
    case cancelled

    var accessibilityValue: LocalizedStringKey {
        switch self {
        case .open: return "Incomplete"
        case .inProgress: return "In progress"
        case .done: return "Completed"
        case .cancelled: return "Canceled"
        }
    }
}

/// The to-do checkbox. Pass `action` to make it tappable, nil to display only.
/// `isDashed` draws the dashed outline of a Someday to-do (seen on the Mac captures).
struct ThingsCheckbox: View {
    let state: ThingsCheckboxState
    var size: CGFloat = ThingsMetrics.Checkbox.size
    var action: (() -> Void)? = nil
    var isDashed: Bool = false

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) { box }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(.isButton)
            } else {
                box
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Checkbox"))
        .accessibilityValue(Text(state.accessibilityValue))
    }

    private var box: some View {
        ZStack {
            shape.fill(fillColor)
            outline
            glyph
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .animation(ThingsMotion.resolved(ThingsMotion.checkboxToggle, reduceMotion: reduceMotion), value: state)
    }

    @ViewBuilder
    private var outline: some View {
        if isDashed && state == .open {
            shape.strokeBorder(
                borderColor,
                style: StrokeStyle(lineWidth: ThingsMetrics.Checkbox.borderWidth, dash: ThingsMetrics.Checkbox.somedayDash)
            )
        } else {
            shape.strokeBorder(borderColor, lineWidth: ThingsMetrics.Checkbox.borderWidth)
        }
    }

    private var shape: RoundedRectangle {
        let radius = ThingsMetrics.Checkbox.isCircular ? size / 2 : ThingsMetrics.Checkbox.cornerRadius
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    private var fillColor: Color {
        switch state {
        case .done: return palette[.accent]
        case .cancelled: return palette[.textSecondary]
        case .open, .inProgress: return Color.clear
        }
    }

    private var borderColor: Color {
        switch state {
        case .done: return palette[.accent]
        case .cancelled: return palette[.textSecondary]
        case .inProgress: return palette[.accent]
        case .open: return palette[.checkboxBorder]
        }
    }

    @ViewBuilder
    private var glyph: some View {
        switch state {
        case .done:
            Image(systemName: ThingsIcons.checkmark)
                .font(.system(size: size * ThingsMetrics.Checkbox.glyphScale, weight: .bold))
                .foregroundStyle(Color.white)
                .transition(.scale(scale: 0.3).combined(with: .opacity))
        case .cancelled:
            Image(systemName: ThingsIcons.cancelled)
                .font(.system(size: size * ThingsMetrics.Checkbox.glyphScale, weight: .bold))
                .foregroundStyle(Color.white)
                .transition(.scale(scale: 0.3).combined(with: .opacity))
        case .inProgress:
            Circle()
                .fill(palette[.accent])
                .frame(width: size * ThingsMetrics.Checkbox.inProgressDotScale,
                       height: size * ThingsMetrics.Checkbox.inProgressDotScale)
                .transition(.scale(scale: 0.3).combined(with: .opacity))
        case .open:
            EmptyView()
        }
    }
}

#Preview("Checkbox light") {
    HStack(spacing: 16) {
        ThingsCheckbox(state: .open)
        ThingsCheckbox(state: .inProgress)
        ThingsCheckbox(state: .done)
        ThingsCheckbox(state: .cancelled)
        ThingsCheckbox(state: .open, isDashed: true)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .light))
    .environment(\.colorScheme, .light)
}

#Preview("Checkbox dark") {
    HStack(spacing: 16) {
        ThingsCheckbox(state: .open)
        ThingsCheckbox(state: .inProgress)
        ThingsCheckbox(state: .done)
        ThingsCheckbox(state: .cancelled)
        ThingsCheckbox(state: .open, isDashed: true)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .dark))
    .environment(\.colorScheme, .dark)
}
