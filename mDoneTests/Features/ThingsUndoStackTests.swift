import XCTest
@testable import mDone

/// Collects what the closures of the commands did, in order.
@MainActor
private final class UndoLog {
    var entries: [String] = []
}

@MainActor
final class ThingsUndoStackTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func command(
        _ title: String,
        key: String? = nil,
        log: UndoLog
    ) -> ThingsUndoCommand {
        ThingsUndoCommand(
            title: title,
            coalescingKey: key,
            undo: { log.entries.append("undo \(title)") },
            redo: { log.entries.append("redo \(title)") }
        )
    }

    func testEmptyStackHasNothingToUndoOrRedo() {
        var stack = ThingsUndoStack()
        XCTAssertFalse(stack.canUndo)
        XCTAssertFalse(stack.canRedo)
        XCTAssertNil(stack.undoTitle)
        XCTAssertNil(stack.popUndo())
        XCTAssertNil(stack.popRedo())
    }

    func testUndoThenRedoRunsTheClosuresInOrder() async {
        let log = UndoLog()
        var stack = ThingsUndoStack()
        stack.record(command("A", log: log), now: t0)
        stack.record(command("B", log: log), now: t0.addingTimeInterval(10))
        XCTAssertEqual(stack.undoTitle, "B")

        let first = stack.popUndo()
        await first?.undo()
        let second = stack.popUndo()
        await second?.undo()
        XCTAssertEqual(log.entries, ["undo B", "undo A"])
        XCTAssertFalse(stack.canUndo)
        XCTAssertEqual(stack.redoTitle, "A")

        let again = stack.popRedo()
        await again?.redo()
        XCTAssertEqual(log.entries.last, "redo A")
        XCTAssertEqual(stack.undoTitle, "A")
        XCTAssertEqual(stack.redoTitle, "B")
    }

    func testRecordingClearsTheRedoHistory() {
        let log = UndoLog()
        var stack = ThingsUndoStack()
        stack.record(command("A", log: log), now: t0)
        _ = stack.popUndo()
        XCTAssertTrue(stack.canRedo)
        stack.record(command("B", log: log), now: t0.addingTimeInterval(10))
        XCTAssertFalse(stack.canRedo)
        XCTAssertEqual(stack.undoTitle, "B")
    }

    func testDepthIsCappedAndTheOldestStepIsDropped() {
        let log = UndoLog()
        var stack = ThingsUndoStack()
        for index in 0..<(ThingsUndoStack.maxDepth + 20) {
            stack.record(command("S\(index)", log: log), now: t0.addingTimeInterval(Double(index) * 10))
        }
        XCTAssertEqual(stack.undoCount, ThingsUndoStack.maxDepth)
        XCTAssertEqual(stack.undoTitle, "S\(ThingsUndoStack.maxDepth + 19)")
        var oldest: String?
        while let popped = stack.popUndo() { oldest = popped.title }
        XCTAssertEqual(oldest, "S20")
    }

    func testMaxDepthIsOneHundred() {
        XCTAssertEqual(ThingsUndoStack.maxDepth, 100)
    }

    func testRapidEditsWithTheSameKeyBecomeOneStep() async {
        let log = UndoLog()
        var stack = ThingsUndoStack()
        stack.record(command("first", key: "when.1", log: log), now: t0)
        stack.record(command("second", key: "when.1", log: log), now: t0.addingTimeInterval(0.5))
        stack.record(command("third", key: "when.1", log: log), now: t0.addingTimeInterval(1.0))
        XCTAssertEqual(stack.undoCount, 1)

        let merged = stack.popUndo()
        await merged?.undo()
        XCTAssertEqual(log.entries, ["undo first"])
        let redone = stack.popRedo()
        await redone?.redo()
        XCTAssertEqual(log.entries, ["undo first", "redo third"])
    }

    func testEditsOutsideTheWindowOrWithAnotherKeyStaySeparate() {
        let log = UndoLog()
        var stack = ThingsUndoStack()
        stack.record(command("a", key: "when.1", log: log), now: t0)
        stack.record(command("b", key: "when.1", log: log), now: t0.addingTimeInterval(ThingsUndoStack.coalescingWindow + 1))
        XCTAssertEqual(stack.undoCount, 2)
        stack.record(command("c", key: "when.2", log: log), now: t0.addingTimeInterval(ThingsUndoStack.coalescingWindow + 1.1))
        XCTAssertEqual(stack.undoCount, 3)
        stack.record(command("d", key: nil, log: log), now: t0.addingTimeInterval(ThingsUndoStack.coalescingWindow + 1.2))
        stack.record(command("e", key: nil, log: log), now: t0.addingTimeInterval(ThingsUndoStack.coalescingWindow + 1.3))
        XCTAssertEqual(stack.undoCount, 5)
    }

    func testDiscardNewestOnlyDropsAMatchingKey() {
        let log = UndoLog()
        var stack = ThingsUndoStack()
        stack.record(command("a", key: "complete.1", log: log), now: t0)
        stack.discardNewest(ifKey: "complete.2")
        XCTAssertEqual(stack.undoCount, 1)
        stack.discardNewest(ifKey: "complete.1")
        XCTAssertEqual(stack.undoCount, 0)
    }

    func testClearEmptiesBothHistories() {
        let log = UndoLog()
        var stack = ThingsUndoStack()
        stack.record(command("a", log: log), now: t0)
        stack.record(command("b", log: log), now: t0.addingTimeInterval(10))
        _ = stack.popUndo()
        stack.clear()
        XCTAssertFalse(stack.canUndo)
        XCTAssertFalse(stack.canRedo)
    }
}
