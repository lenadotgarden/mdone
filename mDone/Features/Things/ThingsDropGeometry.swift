import Foundation
import CoreGraphics

// Where a dragged to-do would land, from the pointer height and the row frames
// (docs/things-spec/08-drag-and-drop.md). Pure: the list gives numbers, gets numbers.

/// The vertical extent of a laid out row, in the list's coordinate space.
struct ThingsDropRowFrame: Equatable {
    var minY: CGFloat
    var maxY: CGFloat

    var midY: CGFloat { (minY + maxY) / 2 }
    var height: CGFloat { maxY - minY }
}

/// A section of the list as the geometry sees it: its id and its rows, top to bottom.
struct ThingsDropLayoutSection: Equatable {
    let id: String
    let rowIDs: [Int64]
}

/// An insertion point: between the rows `index - 1` and `index` of the section, in the
/// order currently shown (the dragged row included when it is in that section).
/// `index` runs from 0 (above the first row) to the row count (below the last).
struct ThingsDropSlot: Equatable {
    let sectionID: String
    let index: Int
}

/// Where the dragged row comes from, in the order currently shown.
struct ThingsDropSource: Equatable {
    let sectionID: String
    let index: Int
}

enum ThingsDropGeometry {
    /// The slot for a pointer at `pointerY`: above the first row whose middle is below the
    /// pointer, or below the last row. Between two sections (the header gap), the pointer
    /// picks the nearer side. Rows without a frame (not laid out yet, the list is lazy) are
    /// skipped but keep their index. Nil when no row has a frame.
    ///
    /// Pass only the sections the dragged to-do may land in: the pointer over any other
    /// section then snaps to the nearest allowed slot.
    static func slot(
        sections: [ThingsDropLayoutSection],
        frames: [Int64: ThingsDropRowFrame],
        pointerY: CGFloat
    ) -> ThingsDropSlot? {
        var previous: (sectionID: String, index: Int, frame: ThingsDropRowFrame)?
        for section in sections {
            for (index, id) in section.rowIDs.enumerated() {
                guard let frame = frames[id] else { continue }
                if pointerY < frame.midY {
                    if let before = previous, before.sectionID != section.id {
                        let boundary = (before.frame.maxY + frame.minY) / 2
                        if pointerY < boundary {
                            return ThingsDropSlot(sectionID: before.sectionID, index: before.index + 1)
                        }
                    }
                    return ThingsDropSlot(sectionID: section.id, index: index)
                }
                previous = (section.id, index, frame)
            }
        }
        guard let last = previous else { return nil }
        return ThingsDropSlot(sectionID: last.sectionID, index: last.index + 1)
    }

    /// How far the row at `index` of section `sectionID` slides (positive is down) so that
    /// the rows open the slot and close the place the dragged row left. `rowHeight` is the
    /// height of the dragged row. The dragged row itself is hidden by the caller.
    static func shift(
        forRowAt index: Int,
        in sectionID: String,
        source: ThingsDropSource,
        slot: ThingsDropSlot,
        rowHeight: CGFloat
    ) -> CGFloat {
        if sectionID == source.sectionID && sectionID == slot.sectionID {
            let landed = slot.index > source.index ? slot.index - 1 : slot.index
            if landed > source.index && index > source.index && index <= landed { return -rowHeight }
            if landed < source.index && index >= landed && index < source.index { return rowHeight }
            return 0
        }
        if sectionID == slot.sectionID && index >= slot.index { return rowHeight }
        if sectionID == source.sectionID && index > source.index { return -rowHeight }
        return 0
    }
}
