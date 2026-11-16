import Foundation

/// Reads the text typed in the header field of the When and Deadline popovers
/// ("tomorrow", "in 3 days", "sept 25", "someday", "this evening"). It reuses
/// `ThingsNaturalLanguage`, so the words are the same as in Quick Entry. No project,
/// tag or estimate is looked for.
enum ThingsWhenInput {
    private static func mapper(now: Date, calendar: Calendar, locale: Locale) -> ThingsNaturalLanguage {
        ThingsNaturalLanguage(
            projects: [],
            labels: [],
            isEnabled: true,
            now: now,
            calendar: calendar,
            locale: locale,
            usesDataDetector: false
        )
    }

    /// The When the text names, nil when it names none. A date in the past reads as Today.
    static func parseWhen(
        _ text: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> ThingsWhen? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return mapper(now: now, calendar: calendar, locale: locale).plan(for: trimmed).when
    }

    /// The day the text names, for the Deadline field. Someday and unknown words give
    /// nil; This Evening means today.
    static func parseDay(
        _ text: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> Date? {
        guard let when = parseWhen(text, now: now, calendar: calendar, locale: locale) else { return nil }
        switch when {
        case .today, .thisEvening:
            return calendar.startOfDay(for: now)
        case .date(let day):
            return calendar.startOfDay(for: day)
        case .someday, .none:
            return nil
        }
    }
}
