import SwiftUI

#if os(iOS)
/// The round plus button at the bottom right of a list (spec 03 "Magic Plus").
/// Tap opens a new to-do row at the top of the list.
///
/// TODO: the drag behavior (insert position, Inbox target, heading at the left
/// edge) is not built, see docs/things-spec/DEVIATIONS.md.
struct ThingsMagicPlusButton: View {
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Image(systemName: ThingsIcons.add)
                .font(.system(size: ThingsMetrics.MagicPlus.glyphSize, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: ThingsMetrics.MagicPlus.size, height: ThingsMetrics.MagicPlus.size)
                .background(Circle().fill(ThingsPalette(scheme)[.accent]))
                .shadow(
                    color: Color.black.opacity(ThingsColorOpacity.cardShadow * 2),
                    radius: ThingsMetrics.MagicPlus.shadowRadius,
                    x: 0,
                    y: ThingsMetrics.MagicPlus.shadowOffsetY
                )
        }
        .buttonStyle(ThingsMagicPlusButtonStyle())
        .accessibilityLabel(Text("New To-Do"))
    }
}

private struct ThingsMagicPlusButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? ThingsMetrics.MagicPlus.pressedScale : 1)
            .animation(ThingsMotion.checkboxToggle, value: configuration.isPressed)
    }
}
#endif
