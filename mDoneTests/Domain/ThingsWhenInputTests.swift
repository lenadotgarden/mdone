import XCTest
@testable import mDone

/// The text field of the When and Deadline popovers.
final class ThingsWhenInputTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private let locale = Locale(identifier: "en_US")

    /// Monday 2026-11-16 at 10:00 UTC.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 10)) ?? Date()
    }

    private var tomorrow: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 17)) ?? Date()
    }

    func testEmptyTextNamesNothing() {
        XCTAssertNil(ThingsWhenInput.parseWhen("   ", now: now, calendar: calendar, locale: locale))
        XCTAssertNil(ThingsWhenInput.parseDay("", now: now, calendar: calendar, locale: locale))
    }

    func testKeywordsGiveSomedayAndThisEvening() {
        XCTAssertEqual(ThingsWhenInput.parseWhen("someday", now: now, calendar: calendar, locale: locale), .someday)
        XCTAssertEqual(
            ThingsWhenInput.parseWhen("this evening", now: now, calendar: calendar, locale: locale),
            .thisEvening
        )
    }

    func testTomorrowGivesTheNextDay() {
        XCTAssertEqual(
            ThingsWhenInput.parseWhen("tomorrow", now: now, calendar: calendar, locale: locale),
            .date(tomorrow)
        )
        XCTAssertEqual(ThingsWhenInput.parseDay("tomorrow", now: now, calendar: calendar, locale: locale), tomorrow)
    }

    func testADeadlineFieldHasNoSomeday() {
        XCTAssertNil(ThingsWhenInput.parseDay("someday", now: now, calendar: calendar, locale: locale))
    }
}
