import XCTest
@testable import mDone

final class ThingsShortcutTableTests: XCTestCase {
    func testGoToShortcutsAreCommandOneToSix() {
        let expected: [(ThingsCommandID, String)] = [
            (.goInbox, "1"), (.goToday, "2"), (.goUpcoming, "3"),
            (.goAnytime, "4"), (.goSomeday, "5"), (.goLogbook, "6")
        ]
        for (id, key) in expected {
            let chord = ThingsShortcutTable.chord(for: id)
            XCTAssertEqual(chord, ThingsKeyChord(key, command: true), "\(id)")
        }
    }

    func testVerifiedCreateAndEditShortcuts() {
        XCTAssertEqual(ThingsShortcutTable.chord(for: .newTodo), ThingsKeyChord("n", command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .newProject), ThingsKeyChord("n", option: true, command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .newHeading), ThingsKeyChord("n", shift: true, command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .complete), ThingsKeyChord("k", command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .cancel), ThingsKeyChord("k", option: true, command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .duplicate), ThingsKeyChord("d", command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .showWhen), ThingsKeyChord("s", command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .addDeadline), ThingsKeyChord("d", shift: true, command: true))
    }

    func testNoTwoImplementedCommandsShareAChord() {
        XCTAssertEqual(ThingsShortcutTable.conflicts, [])
    }

    func testEveryCommandHasOneEntry() {
        for id in ThingsCommandID.allCases {
            let count = ThingsShortcutTable.entries.filter { $0.id == id }.count
            XCTAssertEqual(count, 1, "\(id)")
        }
    }

    func testCommandLookupAnswersOnlyImplementedEntries() {
        XCTAssertEqual(ThingsShortcutTable.command(for: ThingsKeyChord("2", command: true)), .goToday)
        // New Heading is a TODO: its chord triggers nothing.
        XCTAssertNil(ThingsShortcutTable.command(for: ThingsKeyChord("n", shift: true, command: true)))
    }

    func testTodoEntriesCarryAReason() {
        XCTAssertFalse(ThingsShortcutTable.todoEntries.isEmpty)
        for entry in ThingsShortcutTable.todoEntries {
            XCTAssertFalse(entry.note.isEmpty, "\(entry.id)")
        }
    }

    func testGoCommandsMapToLists() {
        for list in ThingsList.allCases {
            let id = ThingsShortcutTable.goCommand(for: list)
            XCTAssertEqual(ThingsShortcutTable.list(for: id), list)
            XCTAssertTrue(ThingsShortcutTable.goCommands.contains(id))
        }
        XCTAssertNil(ThingsShortcutTable.list(for: .newTodo))
    }

    func testDisplayUsesMacModifierOrder() {
        let chord = ThingsKeyChord("n", control: true, option: true, shift: true, command: true)
        XCTAssertEqual(chord.display, "\u{2303}\u{2325}\u{21E7}\u{2318}N")
    }
}

final class ThingsShortcutTableEditingTests: XCTestCase {
    func testUndoRedoAndSpaceChords() {
        XCTAssertEqual(ThingsShortcutTable.chord(for: .undo), ThingsKeyChord("z", command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .redo), ThingsKeyChord("z", shift: true, command: true))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .newTodoBelow), ThingsKeyChord("space"))
        XCTAssertEqual(ThingsShortcutTable.chord(for: .deleteItem), ThingsKeyChord("delete"))
    }

    func testUndoAndRedoAreMenuSafeButSpaceAndDeleteAreNot() {
        XCTAssertEqual(ThingsShortcutTable.command(for: ThingsKeyChord("z", command: true)), .undo)
        // Space and Delete have no Command or Control: the list handles them, not the menu.
        XCTAssertFalse(ThingsShortcutTable.chord(for: .newTodoBelow)?.command ?? true)
        XCTAssertFalse(ThingsShortcutTable.chord(for: .deleteItem)?.command ?? true)
    }

    func testReorderChordsAreImplemented() {
        for id in [ThingsCommandID.moveItemUp, .moveItemDown, .moveItemToTop, .moveItemToBottom] {
            XCTAssertEqual(ThingsShortcutTable.entry(for: id)?.isImplemented, true, "\(id)")
        }
    }
}
