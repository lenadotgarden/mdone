import Foundation

/// How a to-do repeats, in Vikunja's two fields (07 section 9).
struct ThingsNaturalLanguageRepeat: Equatable {
    /// Seconds between two occurrences. 0 in monthly mode.
    let repeatAfter: Int64
    /// 0 = fixed interval, 1 = monthly (`TaskRecurrence`).
    let repeatMode: Int64
}

/// What a line of natural language asks to create: the title and every Things
/// field it named. Built by `ThingsNaturalLanguage.plan(for:)`, applied by
/// `ThingsListViewModel.create(plan:...)`.
struct ThingsNaturalLanguagePlan: Equatable {
    /// The text without the words that became fields. Never empty for a
    /// non-empty input: when every word was consumed the raw text is kept.
    var title: String
    /// nil = the line did not name a When, the list's own default applies.
    var when: ThingsWhen?
    /// Deadline day, stored at 12:00 local (07 section 6).
    var deadline: Date?
    /// Absolute reminder, set when the text named a clock time.
    var reminder: Date?
    var projectID: Int64?
    var projectName: String?
    var labelIDs: [Int64] = []
    var tagNames: [String] = []
    /// 0 = none, 1 to 5 as typed with `!1` to `!5`.
    var priority: Int64 = 0
    var estimateSeconds: TimeInterval?
    var repeatRule: ThingsNaturalLanguageRepeat?

    init(title: String) {
        self.title = title
    }

    /// True when the line named at least one field. A plan without effect is
    /// not worth a special creation path: the title is the typed text.
    var hasEffect: Bool {
        when != nil || deadline != nil || reminder != nil || projectID != nil
            || !labelIDs.isEmpty || priority != 0 || estimateSeconds != nil || repeatRule != nil
    }
}

/// One piece of the live preview line under the field.
struct ThingsNaturalLanguageChip: Equatable, Identifiable {
    enum Kind: String, Equatable {
        case when, deadline, reminder, tag, project, priority, estimate, repeating
    }

    let kind: Kind
    let text: String

    var id: String { kind.rawValue + "." + text }
}

/// Natural language for Things entry points (Léna's request: type the whole
/// to-do in one line). A pure mapper on top of `SmartTaskParser`: it keeps the
/// parser's syntax and adds the Things vocabulary the parser has no notion of.
///
/// Syntax, all case-insensitive:
/// - `+Project` or `#Project`: project or Area by name (parser rule, unique
///   prefix allowed). `*tag`: an existing tag (parser rule). `!1` to `!5`: priority.
/// - When: `today`, `tomorrow`, weekdays, `next week`, `in 3 days`, `Sept 25`,
///   `25/9`, `2026-12-01` (parser rules). `this evening`, `tonight`, `ce soir`
///   make This Evening. `someday` makes Someday.
/// - A clock time (`at 5pm`, `17:30`, `noon`) adds a reminder at that time.
/// - Deadline: a date right after `by`, `due`, `due on`, `deadline`, `before`
///   (or French `avant`, `pour`, `d'ici`, `echeance`).
/// - Estimate: `~30m`, `~1h`, `~1h30`, `~90`.
/// - Repeat: `daily`, `weekly`, `monthly`, `yearly`, `every day`, `every 2 weeks`,
///   `every other week`, `every monday` (weekly, starting on that weekday).
/// - French: `aujourd'hui`, `demain`, `apres-demain`, `lundi` to `dimanche`
///   (with `prochain`, `matin`, `soir`, `apres-midi`), `dans 3 jours`,
///   `la semaine prochaine`, `le 15 avril`, `a 17h`, `17h30`, `a midi`,
///   `tous les jours`, `chaque semaine`, `toutes les 2 semaines`, `chaque mois`,
///   `tous les ans`, `un jour` at the end of the line (Someday).
///
/// The French words are translated to the parser's English before parsing, so
/// the parser stays the one date engine.
struct ThingsNaturalLanguage {
    let projects: [SmartTaskParser.Candidate]
    let labels: [SmartTaskParser.Candidate]
    /// False reproduces the "Smart parsing" preference being off: the title is
    /// the typed text and nothing else.
    let isEnabled: Bool
    let now: Date
    let calendar: Calendar
    let locale: Locale
    let defaultDueTime: DefaultDueTimePreference
    let usesDataDetector: Bool

    init(
        projects: [SmartTaskParser.Candidate],
        labels: [SmartTaskParser.Candidate],
        isEnabled: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .app,
        locale: Locale = .current,
        defaultDueTime: DefaultDueTimePreference = .current(),
        usesDataDetector: Bool = true
    ) {
        self.projects = projects
        self.labels = labels
        self.isEnabled = isEnabled
        self.now = now
        self.calendar = calendar
        self.locale = locale
        self.defaultDueTime = defaultDueTime
        self.usesDataDetector = usesDataDetector
    }

    /// From the app's models. Archived projects, pseudo-projects (ids at or
    /// below zero) and the reserved `things:` labels are not offered, like in
    /// `SmartTaskParser`.
    init(
        projectModels: [Project],
        labelModels: [VLabel],
        isEnabled: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .app,
        locale: Locale = .current,
        defaultDueTime: DefaultDueTimePreference = .current(),
        usesDataDetector: Bool = true
    ) {
        let projectCandidates = projectModels
            .filter { $0.id > 0 && $0.isArchived != true }
            .map { SmartTaskParser.Candidate(id: $0.id, name: $0.title) }
        let labelCandidates = labelModels
            .filter { !ThingsReservedLabels.isReserved($0.title) }
            .map { SmartTaskParser.Candidate(id: $0.id, name: $0.title) }
        self.init(
            projects: projectCandidates,
            labels: labelCandidates,
            isEnabled: isEnabled,
            now: now,
            calendar: calendar,
            locale: locale,
            defaultDueTime: defaultDueTime,
            usesDataDetector: usesDataDetector
        )
    }

    // MARK: - Plan

    func plan(for text: String) -> ThingsNaturalLanguagePlan {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isEnabled, !raw.isEmpty else { return ThingsNaturalLanguagePlan(title: raw) }

        var work = raw
        let estimate = Self.extractEstimate(&work)
        let repeatRule = Self.extractRepeat(&work)
        let keywords = Self.extractWhenKeywords(&work)

        let beforeTranslation = work
        work = Self.translateFrench(work)
        let wasTranslated = work != beforeTranslation

        let deadline = extractDeadline(&work)
        var parse = makeParser().parse(work)
        if wasTranslated, deadline == nil, parse.dueDate == nil {
            // The French words did not end up as a date (31 fevrier): keep the
            // text as typed rather than a half-translated title.
            work = beforeTranslation
            parse = makeParser().parse(work)
        }

        var plan = ThingsNaturalLanguagePlan(title: Self.strippedTitle(parse, fallback: raw))
        plan.deadline = deadline
        plan.estimateSeconds = estimate
        plan.repeatRule = repeatRule
        plan.priority = Int64(parse.priority ?? 0)

        if let projectId = parse.projectId {
            plan.projectID = projectId
            plan.projectName = projects.first(where: { $0.id == projectId })?.name
        }
        plan.labelIDs = parse.labelIds
        plan.tagNames = parse.labelIds.compactMap { id in labels.first(where: { $0.id == id })?.name }

        var when: ThingsWhen?
        var reminder: Date?
        if let due = parse.dueDate {
            let day = calendar.startOfDay(for: due)
            let today = calendar.startOfDay(for: now)
            when = day <= today ? ThingsWhen.today : ThingsWhen.date(day)
            if parse.dueDateHasTime {
                reminder = due
            }
        }
        if keywords.evening {
            var isFuture = false
            if let current = when, case .date = current { isFuture = true }
            if !isFuture { when = ThingsWhen.thisEvening }
        }
        if keywords.someday {
            // Someday wins over any date, as the reserved label does (07 section 8).
            when = ThingsWhen.someday
            reminder = nil
        }
        if repeatRule != nil, when == nil, deadline == nil {
            // A repeating to-do needs a date to repeat from.
            when = ThingsWhen.today
        }
        plan.when = when
        plan.reminder = reminder
        return plan
    }

    private func makeParser() -> SmartTaskParser {
        SmartTaskParser(
            projects: projects,
            labels: labels,
            now: now,
            calendar: calendar,
            locale: locale,
            defaultDueTime: defaultDueTime,
            usesDataDetector: usesDataDetector
        )
    }

    /// The parser's own title falls back to the whole text when nothing is
    /// left; this one falls back to the text as typed, so a French "demain"
    /// is not turned into "tomorrow".
    private static func strippedTitle(_ parse: SmartTaskParse, fallback: String) -> String {
        let consumed = parse.matches.flatMap { $0.ranges }.sorted { $0.lowerBound < $1.lowerBound }
        var kept = ""
        var cursor = parse.text.startIndex
        for range in consumed where range.lowerBound >= cursor {
            kept += parse.text[cursor ..< range.lowerBound]
            kept += " "
            cursor = range.upperBound
        }
        kept += parse.text[cursor...]
        let stripped = SmartTaskParse.collapsingWhitespace(kept)
        return stripped.isEmpty ? SmartTaskParse.collapsingWhitespace(fallback) : stripped
    }

    // MARK: - Deadline

    /// `by friday`, `due 2026-12-01`, `avant le 15 avril`: a marker word and,
    /// right after it, a date the parser understands. The marker and the date
    /// leave the text; the day (at 12:00) is the deadline.
    private func extractDeadline(_ work: inout String) -> Date? {
        let nsText = work as NSString
        let markers = Self.deadlineMarker.matches(in: work, range: NSRange(location: 0, length: nsText.length))
        if markers.isEmpty { return nil }
        let noCandidates: [SmartTaskParser.Candidate] = []
        let subParser = SmartTaskParser(
            projects: noCandidates,
            labels: noCandidates,
            now: now,
            calendar: calendar,
            locale: locale,
            defaultDueTime: defaultDueTime,
            usesDataDetector: usesDataDetector
        )
        for marker in markers {
            let restStart = marker.range.location + marker.range.length
            let rest = nsText.substring(from: restStart)
            let parse = subParser.parse(rest)
            guard let due = parse.dueDate,
                  let hit = parse.matches.first(where: { $0.field == .dueDate }) else { continue }
            let spans = hit.ranges.map { NSRange($0, in: rest) }
            guard let first = spans.map({ $0.location }).min(), first == 0 else { continue }
            let end = spans.map { $0.location + $0.length }.max() ?? 0
            let removal = NSRange(location: marker.range.location, length: (restStart - marker.range.location) + end)
            work = nsText.replacingCharacters(in: removal, with: " ")
            return ThingsWhen.noonLocal(due, calendar: calendar)
        }
        return nil
    }

    // MARK: - Estimate

    /// `~30m`, `~1h`, `~1h30`, `~1.5h`, `~90` (minutes).
    private static func extractEstimate(_ work: inout String) -> TimeInterval? {
        guard let match = firstMatch(estimateRegex, in: work) else { return nil }
        var seconds: Double = 0
        if let hours = group(match, 1, in: work), let value = Double(hours.replacingOccurrences(of: ",", with: ".")) {
            seconds += value * 3600
            if let extra = group(match, 2, in: work), let minutes = Double(extra) {
                seconds += minutes * 60
            }
        } else if let minutes = group(match, 3, in: work), let value = Double(minutes) {
            seconds += value * 60
        }
        guard seconds > 0 else { return nil }
        replace(match, in: &work, with: " ")
        return seconds
    }

    // MARK: - Repeat

    private static func extractRepeat(_ work: inout String) -> ThingsNaturalLanguageRepeat? {
        if let match = firstMatch(repeatEveryWeekdayRegex, in: work) {
            let day = group(match, 1, in: work) ?? ""
            replace(match, in: &work, with: day)
            return makeRepeat(unit: "week", count: 1)
        }
        if let match = firstMatch(repeatFrenchWeekdayRegex, in: work) {
            let day = group(match, 1, in: work) ?? ""
            replace(match, in: &work, with: day)
            return makeRepeat(unit: "week", count: 1)
        }
        if let match = firstMatch(repeatEveryRegex, in: work) {
            let count = group(match, 1, in: work).flatMap { Int($0) } ?? (group(match, 2, in: work) != nil ? 2 : 1)
            let unit = group(match, 3, in: work) ?? ""
            if let rule = makeRepeat(unit: unit, count: count) {
                replace(match, in: &work, with: " ")
                return rule
            }
        }
        if let match = firstMatch(repeatFrenchEveryRegex, in: work) {
            let count = group(match, 1, in: work).flatMap { Int($0) } ?? 1
            let unit = group(match, 2, in: work) ?? ""
            if let rule = makeRepeat(unit: unit, count: count) {
                replace(match, in: &work, with: " ")
                return rule
            }
        }
        if let match = firstMatch(repeatAdverbRegex, in: work) {
            let word = (group(match, 1, in: work) ?? "").lowercased()
            let units = [
                "daily": "day", "weekly": "week", "monthly": "month", "yearly": "year", "annually": "year",
                "quotidien": "day", "quotidienne": "day", "hebdomadaire": "week",
                "mensuel": "month", "mensuelle": "month", "annuel": "year", "annuelle": "year",
            ]
            if let unit = units[word], let rule = makeRepeat(unit: unit, count: 1) {
                replace(match, in: &work, with: " ")
                return rule
            }
        }
        return nil
    }

    private static func makeRepeat(unit: String, count: Int) -> ThingsNaturalLanguageRepeat? {
        let n = Int64(max(count, 1))
        let key = unit.lowercased()
        if key.hasPrefix("day") || key.hasPrefix("jour") {
            return ThingsNaturalLanguageRepeat(repeatAfter: 86_400 * n, repeatMode: 0)
        }
        if key.hasPrefix("week") || key.hasPrefix("semaine") {
            return ThingsNaturalLanguageRepeat(repeatAfter: 604_800 * n, repeatMode: 0)
        }
        if key.hasPrefix("month") || key == "mois" {
            // Vikunja's monthly mode is one month only: longer steps are
            // approximated by 30 day intervals.
            if n == 1 { return ThingsNaturalLanguageRepeat(repeatAfter: 0, repeatMode: 1) }
            return ThingsNaturalLanguageRepeat(repeatAfter: 2_592_000 * n, repeatMode: 0)
        }
        if key.hasPrefix("year") || key.hasPrefix("an") {
            return ThingsNaturalLanguageRepeat(repeatAfter: 31_536_000 * n, repeatMode: 0)
        }
        return nil
    }

    // MARK: - This Evening and Someday

    private static func extractWhenKeywords(_ work: inout String) -> (evening: Bool, someday: Bool) {
        var evening = false
        var someday = false
        if let match = firstMatch(eveningRegex, in: work) {
            evening = true
            replace(match, in: &work, with: " ")
        }
        if let match = firstMatch(somedayRegex, in: work) {
            someday = true
            replace(match, in: &work, with: " ")
        } else if let match = firstMatch(somedayFrenchRegex, in: work) {
            someday = true
            replace(match, in: &work, with: " ")
        }
        return (evening, someday)
    }

    // MARK: - French

    private static let frenchWeekdays = [
        "lundi": "monday", "mardi": "tuesday", "mercredi": "wednesday", "jeudi": "thursday",
        "vendredi": "friday", "samedi": "saturday", "dimanche": "sunday",
    ]

    private static let frenchMonths = [
        "janvier": "january", "février": "february", "fevrier": "february", "mars": "march",
        "avril": "april", "mai": "may", "juin": "june", "juillet": "july", "août": "august",
        "aout": "august", "septembre": "september", "octobre": "october", "novembre": "november",
        "décembre": "december", "decembre": "december",
    ]

    /// French words to the English the parser reads. Skips a word that follows
    /// a `+`, `#`, `*` or `!` sigil, so "+Demain" stays a project name.
    static func translateFrench(_ text: String) -> String {
        var result = text

        // Day words, with an optional day part: "lundi soir", "demain matin".
        result = replaceAll(frenchDayRegex, in: result) { match, source in
            let word = (group(match, 1, in: source) ?? "").lowercased().replacingOccurrences(of: "’", with: "'")
            var english: String
            switch word {
            case "demain": english = "tomorrow"
            case "aujourd'hui": english = "today"
            case "après-demain", "apres-demain": english = "in 2 days"
            default: english = frenchWeekdays[word] ?? word
            }
            if let part = group(match, 2, in: source)?.lowercased() {
                if part == "matin" {
                    english += " morning"
                } else if part == "soir" {
                    english += " evening"
                } else {
                    english += " afternoon"
                }
            }
            return english
        }

        result = replaceAll(frenchNextWeekRegex, in: result) { _, _ in "next week" }
        result = replaceAll(frenchNextMonthRegex, in: result) { _, _ in "next month" }

        result = replaceAll(frenchInRegex, in: result) { match, source in
            let amount = (group(match, 1, in: source) ?? "1").lowercased()
            let count = Int(amount) ?? 1
            let unit = (group(match, 2, in: source) ?? "jours").lowercased()
            return "in \(count) " + (unit.hasPrefix("semaine") ? "weeks" : "days")
        }

        // 15 avril, le 1er mai 2027
        result = replaceAll(frenchDateRegex, in: result) { match, source in
            guard let day = group(match, 1, in: source),
                  let month = group(match, 2, in: source)?.lowercased(),
                  let english = frenchMonths[month] else { return group(match, 0, in: source) ?? "" }
            var out = "\(day) \(english)"
            if let year = group(match, 3, in: source) {
                out += " \(year)"
            }
            return out
        }

        // à 17h, 17h30. A bare "2h" is a duration ("réunion de 2h"), not a time.
        result = replaceAll(frenchTimeRegex, in: result) { match, source in
            let whole = group(match, 0, in: source) ?? ""
            let hasAt = group(match, 1, in: source) != nil
            let minutes = group(match, 3, in: source)
            guard hasAt || minutes != nil,
                  let hour = group(match, 2, in: source).flatMap({ Int($0) }), (0 ... 23).contains(hour)
            else { return whole }
            let minute = minutes.flatMap { Int($0) } ?? 0
            guard (0 ... 59).contains(minute) else { return whole }
            return "at \(hour):" + (minute < 10 ? "0\(minute)" : "\(minute)")
        }

        result = replaceAll(frenchNoonRegex, in: result) { _, _ in "at noon" }
        result = replaceAll(frenchMidnightRegex, in: result) { _, _ in "at midnight" }
        return result
    }

    // MARK: - Regex helpers

    private static func regex(_ pattern: String) -> NSRegularExpression {
        // Patterns are literals in this file; a bad one is a programmer error.
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    private static func firstMatch(_ expression: NSRegularExpression, in text: String) -> NSTextCheckingResult? {
        expression.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length))
    }

    private static func group(_ match: NSTextCheckingResult, _ index: Int, in text: String) -> String? {
        guard index < match.numberOfRanges else { return nil }
        let range = match.range(at: index)
        guard range.location != NSNotFound else { return nil }
        return (text as NSString).substring(with: range)
    }

    private static func replace(_ match: NSTextCheckingResult, in text: inout String, with replacement: String) {
        text = (text as NSString).replacingCharacters(in: match.range, with: replacement)
    }

    /// Replaces every match, from the end so earlier ranges stay valid.
    private static func replaceAll(
        _ expression: NSRegularExpression,
        in text: String,
        transform: (NSTextCheckingResult, String) -> String
    ) -> String {
        let nsText = text as NSString
        let matches = expression.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        var result = text
        for match in matches.reversed() {
            let replacement = transform(match, text)
            result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
        }
        return result
    }

    /// Not glued to a letter, a digit or a sigil of the parser.
    private static let lead = #"(?<![\p{L}\p{N}+#*!])"#
    private static let tail = #"(?![\p{L}\p{N}'’])"#

    private static let estimateRegex = regex(
        #"(?<!\S)~(?:(\d+(?:[.,]\d+)?)\s*(?:h|hr|hrs|hours?|heures?)(?:\s*(\d{1,2})\s*(?:m|min|mins|minutes?)?)?"#
            + #"|(\d+)\s*(?:m|min|mins|minutes?)?)(?![\p{L}\p{N}])"#
    )

    private static let weekdayNames = "monday|tuesday|wednesday|thursday|friday|saturday|sunday"
    private static let frenchWeekdayNames = "lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche"

    private static let repeatEveryWeekdayRegex = regex(
        lead + #"(?:every|each)\s+("# + weekdayNames + #")s?"# + tail
    )
    private static let repeatFrenchWeekdayRegex = regex(
        lead + #"(?:tous\s+les|chaque)\s+("# + frenchWeekdayNames + #")s?"# + tail
    )
    private static let repeatEveryRegex = regex(
        lead + #"(?:every|each)\s+(?:(\d{1,3})\s+|(other)\s+)?(day|week|month|year)s?"# + tail
    )
    private static let repeatFrenchEveryRegex = regex(
        lead + #"(?:tous\s+les|toutes\s+les|chaque)\s+(?:(\d{1,3})\s+)?(jours?|semaines?|mois|ans?|ann[ée]es?)"# + tail
    )
    private static let repeatAdverbRegex = regex(
        lead
            + #"(daily|weekly|monthly|yearly|annually|quotidienne?|hebdomadaire|mensuel(?:le)?|annuel(?:le)?)"#
            + tail
    )

    private static let eveningRegex = regex(lead + #"(?:this\s+evening|tonight|ce\s+soir)"# + tail)
    private static let somedayRegex = regex(lead + #"(?:someday|some\s+day)"# + tail)
    private static let somedayFrenchRegex = regex(
        lead + #"(?:un\s+jour|un\s+de\s+ces\s+jours|quelque\s+jour)[\s.!]*$"#
    )

    private static let frenchDayRegex = regex(
        #"(?<![\p{L}\p{N}+#*!-])(apr[eè]s-demain|demain|aujourd['’]hui|"# + frenchWeekdayNames + #")"#
            + #"(?:\s+prochain)?(?:\s+(matin|soir|apr[eè]s-midi))?(?![\p{L}\p{N}'’])"#
    )
    private static let frenchNextWeekRegex = regex(lead + #"(?:la\s+)?semaine\s+prochaine"# + tail)
    private static let frenchNextMonthRegex = regex(lead + #"(?:le\s+)?mois\s+prochain"# + tail)
    private static let frenchInRegex = regex(lead + #"dans\s+(\d{1,3}|une?)\s+(jours?|semaines?)"# + tail)
    private static let frenchDateRegex = regex(
        #"(?<![\p{L}\p{N}+#*!/])(?:le\s+)?(\d{1,2})(?:er)?\s+("#
            + #"janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[ée]cembre"#
            + #")(?:\s+(\d{4}))?(?![\p{L}\p{N}])"#
    )
    private static let frenchTimeRegex = regex(
        #"(?<![\p{L}\p{N}:+#*!])(à\s+)?(\d{1,2})\s?h\s?(\d{2})?(?![\p{L}\p{N}])"#
    )
    private static let frenchNoonRegex = regex(#"(?<![\p{L}\p{N}+#*!-])(?:à\s+)?midi(?![\p{L}\p{N}])"#)
    private static let frenchMidnightRegex = regex(#"(?<![\p{L}\p{N}+#*!-])(?:à\s+)?minuit(?![\p{L}\p{N}])"#)

    private static let deadlineMarker = regex(
        lead + #"(?:due(?:\s+(?:on|by))?|by|deadline|before|avant|pour|d['’]ici|[ée]ch[ée]ance)(?:\s+le)?\s+"#
    )
}

// MARK: - Preview chips

extension ThingsNaturalLanguagePlan {
    /// The live preview under the field: When, deadline, reminder, repeat,
    /// project, tags, priority and estimate, in that order.
    func chips(now: Date, calendar: Calendar, locale: Locale) -> [ThingsNaturalLanguageChip] {
        var chips: [ThingsNaturalLanguageChip] = []
        if let when = when, let text = Self.whenText(when, now: now, calendar: calendar, locale: locale) {
            chips.append(ThingsNaturalLanguageChip(kind: .when, text: text))
        }
        if let reminder = reminder {
            chips.append(ThingsNaturalLanguageChip(kind: .reminder, text: Self.timeText(reminder, locale: locale)))
        }
        if let deadline = deadline {
            let day = Self.dayText(deadline, locale: locale, calendar: calendar)
            chips.append(ThingsNaturalLanguageChip(kind: .deadline, text: String(localized: "Deadline \(day)")))
        }
        if let repeatRule = repeatRule,
           let recurrence = TaskRecurrence(repeatAfter: repeatRule.repeatAfter, repeatMode: repeatRule.repeatMode)
        {
            chips.append(ThingsNaturalLanguageChip(kind: .repeating, text: recurrence.label))
        }
        if let projectName = projectName {
            chips.append(ThingsNaturalLanguageChip(kind: .project, text: projectName))
        }
        for name in tagNames {
            chips.append(ThingsNaturalLanguageChip(kind: .tag, text: name))
        }
        if priority > 0 {
            chips.append(ThingsNaturalLanguageChip(kind: .priority, text: String(localized: "Priority \(priority)")))
        }
        if let estimateSeconds = estimateSeconds {
            chips.append(ThingsNaturalLanguageChip(kind: .estimate, text: Self.estimateText(estimateSeconds)))
        }
        return chips
    }

    private static func whenText(_ when: ThingsWhen, now: Date, calendar: Calendar, locale: Locale) -> String? {
        switch when {
        case .today: return String(localized: "Today")
        case .thisEvening: return String(localized: "This Evening")
        case .someday: return String(localized: "Someday")
        case .none: return nil
        case .date(let day):
            let today = calendar.startOfDay(for: now)
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today), calendar.isDate(day, inSameDayAs: tomorrow) {
                return String(localized: "Tomorrow")
            }
            return dayText(day, locale: locale, calendar: calendar)
        }
    }

    private static func dayText(_ date: Date, locale: Locale, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEdMMM")
        return formatter.string(from: date)
    }

    private static func timeText(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter.string(from: date)
    }

    /// 30 min, 1 h, 1 h 30.
    static func estimateText(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(1, Int((seconds / 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return String(localized: "\(minutes) min") }
        if minutes == 0 { return String(localized: "\(hours) h") }
        return String(localized: "\(hours) h \(minutes)")
    }
}
