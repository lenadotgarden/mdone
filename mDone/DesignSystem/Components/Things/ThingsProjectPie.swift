import SwiftUI

/// Project progress circle: an accent ring with a filled sector inside (spec 01 section 2.4).
struct ThingsProjectPie: View {
    /// 0 to 1. Values outside are clamped.
    let progress: Double
    var size: CGFloat = ThingsMetrics.Pie.rowSize
    var tint: ThingsColorToken = .accent

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }
    private var color: Color { ThingsPalette(scheme)[tint] }

    /// Diameter of the area inside ring and gap.
    private var innerDiameter: CGFloat {
        max(size - 2 * (ThingsMetrics.Pie.ringWidth + ThingsMetrics.Pie.gap), 0)
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(color, lineWidth: ThingsMetrics.Pie.ringWidth)
                .frame(width: size, height: size)
            // A circle of half the inner diameter stroked at that half diameter
            // paints a full disc, so trimming it paints a pie sector.
            Circle()
                .trim(from: 0, to: CGFloat(clamped))
                .stroke(color, style: StrokeStyle(lineWidth: innerDiameter / 2))
                .frame(width: innerDiameter / 2, height: innerDiameter / 2)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .animation(ThingsMotion.resolved(ThingsMotion.pieProgress, reduceMotion: reduceMotion), value: clamped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progress"))
        .accessibilityValue(Text("\(Int((clamped * 100).rounded())) percent"))
    }
}

#Preview("Pie light") {
    HStack(spacing: 16) {
        ThingsProjectPie(progress: 0)
        ThingsProjectPie(progress: 0.25)
        ThingsProjectPie(progress: 0.6)
        ThingsProjectPie(progress: 1)
        ThingsProjectPie(progress: 0.5, size: ThingsMetrics.Pie.headerSize)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .light))
    .environment(\.colorScheme, .light)
}

#Preview("Pie dark") {
    HStack(spacing: 16) {
        ThingsProjectPie(progress: 0)
        ThingsProjectPie(progress: 0.25)
        ThingsProjectPie(progress: 0.6)
        ThingsProjectPie(progress: 1)
        ThingsProjectPie(progress: 0.5, size: ThingsMetrics.Pie.headerSize)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .dark))
    .environment(\.colorScheme, .dark)
}
