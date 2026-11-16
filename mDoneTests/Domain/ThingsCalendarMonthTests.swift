import XCTest
@testable import mDone

final class ThingsCalendarMonthTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    func testWeeksAreSevenWideAndMondayFirst() {
        // November 2026 starts on a Sunday: six empty cells before the 1st in a Monday first grid.
        let month = ThingsCalendarMonth.make(containing: date(2026, 11, 16), calendar: calendar)
        XCTAssertTrue(month.weeks.allSatisfy { $0.count == 7 })
        let first = month.weeks[0]
        XCTAssertEqual(first.prefix(6).compactMap { $0 }.count, 0)
        XCTAssertEqual(first[6], date(2026, 11, 1))
    }

    func testMonthHoldsEveryDayOnceInOrder() {
        let month = ThingsCalendarMonth.make(containing: date(2026, 2, 10), calendar: calendar)
        XCTAssertEqual(month.days.count, 28)
        XCTAssertEqual(month.days.first, date(2026, 2, 1))
        XCTAssertEqual(month.days.last, date(2026, 2, 28))
    }

    func testMonthStartingOnAMondayHasNoLeadingCells() {
        // June 2026 starts on a Monday.
        let month = ThingsCalendarMonth.make(containing: date(2026, 6, 15), calendar: calendar)
        XCTAssertEqual(month.weeks[0][0], date(2026, 6, 1))
    }

    func testFirstDayAlignsWithItsWeekdayColumn() {
        // 2026-12-01 is a Tuesday: column 1 of a Monday first grid.
        let month = ThingsCalendarMonth.make(containing: date(2026, 12, 20), calendar: calendar)
        XCTAssertNil(month.weeks[0][0])
        XCTAssertEqual(month.weeks[0][1], date(2026, 12, 1))
    }

    func testWeekdaySymbolsStartOnMonday() {
        let symbols = ThingsCalendarMonth.weekdaySymbols(calendar: calendar)
        XCTAssertEqual(symbols.count, 7)
        XCTAssertEqual(symbols[0], "M")
        XCTAssertEqual(symbols[6], "S")
    }

    func testShiftMovesByWholeMonthsToTheFirstDay() {
        XCTAssertEqual(ThingsCalendarMonth.shift(date(2026, 1, 31), months: 1, calendar: calendar), date(2026, 2, 1))
        XCTAssertEqual(ThingsCalendarMonth.shift(date(2026, 1, 15), months: -1, calendar: calendar), date(2025, 12, 1))
    }

    func testArrowKeysMoveByADayOrAWeek() {
        let day = date(2026, 11, 16)
        XCTAssertEqual(ThingsCalendarMonth.moveFocus(day, .right, calendar: calendar), date(2026, 11, 17))
        XCTAssertEqual(ThingsCalendarMonth.moveFocus(day, .left, calendar: calendar), date(2026, 11, 15))
        XCTAssertEqual(ThingsCalendarMonth.moveFocus(day, .down, calendar: calendar), date(2026, 11, 23))
        XCTAssertEqual(ThingsCalendarMonth.moveFocus(day, .up, calendar: calendar), date(2026, 11, 9))
        XCTAssertEqual(ThingsCalendarMonth.moveFocus(date(2026, 11, 30), .right, calendar: calendar), date(2026, 12, 1))
    }

    func testSameMonth() {
        XCTAssertTrue(ThingsCalendarMonth.sameMonth(date(2026, 11, 1), date(2026, 11, 30), calendar: calendar))
        XCTAssertFalse(ThingsCalendarMonth.sameMonth(date(2026, 11, 30), date(2026, 12, 1), calendar: calendar))
    }
}
