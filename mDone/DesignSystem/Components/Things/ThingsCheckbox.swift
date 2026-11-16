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

/// The checkmark as a path, so it can be drawn stroke by stroke with `trim`.
private struct ThingsCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.88))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.94, y: rect.minY + rect.height * 0.14))
        return path
    }
}

/// The to-do checkbox. Pass `action` to make it tappable, nil to display only.
/// `isDashed` draws the dashed outline of a Someday to-do (seen on the Mac captures).
///
/// Completing fills the box and draws the checkmark in about a quarter of a second
/// (`ThingsMotion.checkDraw`); with Reduce Motion on, both happen at once.
struct ThingsCheckbox: View {
    let state: ThingsCheckboxState
    var size: CGFloat = ThingsMetrics.Checkbox.size
    var action: (() -> Void)? = nil
    var isDashed: Bool = false

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How much of the checkmark is drawn, 0 to 1. A box that is already done when it
    /// first appears starts at 1, so only a tick the user makes animates.
    @State private var drawProgress: CGFloat

    init(
        state: ThingsCheckboxState,
        size: CGFloat = ThingsMetrics.Checkbox.size,
        action: (() -> Void)? = nil,
        isDashed: Bool = false
    ) {
        self.state = state
        self.size = size
        self.action = action
        self.isDashed = isDashed
        _drawProgress = State(initialValue: state == .done ? 1 : 0)
    }

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
        .onChange(of: state) { _, newState in
            withAnimation(ThingsMotion.resolved(ThingsMotion.checkDraw, reduceMotion: reduceMotion)) {
                drawProgress = (newState == .done) ? 1 : 0
            }
        }
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
            ThingsCheckmarkShape()
                .trim(from: 0, to: drawProgress)
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: max(size * ThingsMetrics.Checkbox.checkStrokeScale, 1),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(
                    width: size * ThingsMetrics.Checkbox.glyphScale,
                    height: size * ThingsMetrics.Checkbox.glyphScale
                )
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
