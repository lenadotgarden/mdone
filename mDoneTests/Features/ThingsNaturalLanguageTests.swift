import XCTest
@testable import mDone

/// Pinned to Monday 2026-11-16 10:00 UTC, en_GB, default due time 18:00, no
/// data detector (it reads the real clock).
final class ThingsNaturalLanguageTests: XCTestCase {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        calendar.firstWeekday = 2
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? Date()
    }

    private var now: Date { date(2026, 11, 16, 10, 0) }

    private func mapper(
        enabled: Bool = true,
        extraProjects: [SmartTaskParser.Candidate] = []
    ) -> ThingsNaturalLanguage {
        let baseProjects: [SmartTaskParser.Candidate] = [
            SmartTaskParser.Candidate(id: 1, name: "Inbox"),
            SmartTaskParser.Candidate(id: 2, name: "Home"),
            SmartTaskParser.Candidate(id: 3, name: "Home Improvements"),
            SmartTaskParser.Candidate(id: 4, name: "Work"),
        ]
        let tags: [SmartTaskParser.Candidate] = [
            SmartTaskParser.Candidate(id: 10, name: "shopping"),
            SmartTaskParser.Candidate(id: 11, name: "urgent"),
        ]
        return ThingsNaturalLanguage(
            projects: baseProjects + extraProjects,
            labels: tags,
            isEnabled: enabled,
            now: now,
            calendar: utc,
            locale: Locale(identifier: "en_GB"),
            defaultDueTime: .sixPM,
            usesDataDetector: false
        )
    }

    private func plan(_ text: String) -> ThingsNaturalLanguagePlan {
        mapper().plan(for: text)
    }

    // MARK: - Preference

    func testDisabledKeepsTheTypedText() {
        let result = mapper(enabled: false).plan(for: "  Buy milk tomorrow +Home  ")
        XCTAssertEqual(result.title, "Buy milk tomorrow +Home")
        XCTAssertFalse(result.hasEffect)
    }

    func testPlainTitleHasNoEffect() {
        let result = plan("Buy milk")
        XCTAssertEqual(result.title, "Buy milk")
        XCTAssertFalse(result.hasEffect)
    }

    func testEmptyTextGivesAnEmptyTitle() {
        XCTAssertEqual(plan("   ").title, "")
    }

    func testUnknownTagAndProjectStayInTheTitle() {
        let result = plan("Buy *foo #Nowhere")
        XCTAssertEqual(result.title, "Buy *foo #Nowhere")
        XCTAssertFalse(result.hasEffect)
    }

    // MARK: - When

    func testTomorrowIsAWhen() {
        let result = plan("Buy milk tomorrow")
        XCTAssertEqual(result.title, "Buy milk")
        XCTAssertEqual(result.when, ThingsWhen.date(date(2026, 11, 17)))
        XCTAssertNil(result.reminder)
        XCTAssertNil(result.deadline)
    }

    func testTodayIsAWhen() {
        let result = plan("Call Paul today")
        XCTAssertEqual(result.title, "Call Paul")
        XCTAssertEqual(result.when, ThingsWhen.today)
    }

    func testWeekdayIsTheNextOccurrence() {
        let result = plan("Gym friday")
        XCTAssertEqual(result.title, "Gym")
        XCTAssertEqual(result.when, ThingsWhen.date(date(2026, 11, 20)))
    }

    func testClockTimeAddsAReminder() {
        let result = plan("Call mum tomorrow at 5pm")
        XCTAssertEqual(result.title, "Call mum")
        XCTAssertEqual(result.when, ThingsWhen.date(date(2026, 11, 17)))
        XCTAssertEqual(result.reminder, date(2026, 11, 17, 17, 0))
    }

    func testThisEveningAndTonight() {
        let evening = plan("Dinner with Paul this evening")
        XCTAssertEqual(evening.title, "Dinner with Paul")
        XCTAssertEqual(evening.when, ThingsWhen.thisEvening)
        XCTAssertNil(evening.reminder)

        let tonight = plan("Read tonight")
        XCTAssertEqual(tonight.title, "Read")
        XCTAssertEqual(tonight.when, ThingsWhen.thisEvening)
    }

    func testTonightWithATimeKeepsTheReminder() {
        let result = plan("Film tonight at 8pm")
        XCTAssertEqual(result.title, "Film")
        XCTAssertEqual(result.when, ThingsWhen.thisEvening)
        XCTAssertEqual(result.reminder, date(2026, 11, 16, 20, 0))
    }

    func testSomeday() {
        let result = plan("Learn piano someday")
        XCTAssertEqual(result.title, "Learn piano")
        XCTAssertEqual(result.when, ThingsWhen.someday)
    }

    // MARK: - Deadline

    func testByMakesADeadline() {
        let result = plan("Pay rent by friday")
        XCTAssertEqual(result.title, "Pay rent")
        XCTAssertNil(result.when)
        XCTAssertEqual(result.deadline, date(2026, 11, 20, 12, 0))
    }

    func testDueWithAnAbsoluteDate() {
        let result = plan("Send invoice due 2026-12-01")
        XCTAssertEqual(result.title, "Send invoice")
        XCTAssertEqual(result.deadline, date(2026, 12, 1, 12, 0))
    }

    func testWhenAndDeadlineTogether() {
        let result = plan("Write report tomorrow by friday")
        XCTAssertEqual(result.title, "Write report")
        XCTAssertEqual(result.when, ThingsWhen.date(date(2026, 11, 17)))
        XCTAssertEqual(result.deadline, date(2026, 11, 20, 12, 0))
    }

    func testByInsideAWordIsNotAMarker() {
        let result = plan("Feed the baby friday")
        XCTAssertEqual(result.title, "Feed the baby")
        XCTAssertNil(result.deadline)
        XCTAssertEqual(result.when, ThingsWhen.date(date(2026, 11, 20)))
    }

    // MARK: - Project, tags, priority, estimate

    func testProjectTagAndPriority() {
        let result = plan("Fix tap +Home *urgent !3")
        XCTAssertEqual(result.title, "Fix tap")
        XCTAssertEqual(result.projectID, 2)
        XCTAssertEqual(result.projectName, "Home")
        XCTAssertEqual(result.labelIDs, [11])
        XCTAssertEqual(result.tagNames, ["urgent"])
        XCTAssertEqual(result.priority, 3)
    }

    func testHashNamesAProjectToo() {
        let result = plan("Plan sprint #Work")
        XCTAssertEqual(result.title, "Plan sprint")
        XCTAssertEqual(result.projectID, 4)
    }

    func testEstimate() {
        XCTAssertEqual(plan("Write post ~1h30").estimateSeconds, 5400)
        XCTAssertEqual(plan("Write post ~1h30").title, "Write post")
        XCTAssertEqual(plan("Email ~30m").estimateSeconds, 1800)
        XCTAssertEqual(plan("Email ~90").estimateSeconds, 5400)
        XCTAssertEqual(plan("Study ~2 hours").estimateSeconds, 7200)
    }

    // MARK: - Repeat

    func testRepeatEnglish() {
        let weekly = plan("Water plants every week")
        XCTAssertEqual(weekly.title, "Water plants")
        XCTAssertEqual(weekly.repeatRule, ThingsNaturalLanguageRepeat(repeatAfter: 604_800, repeatMode: 0))
        XCTAssertEqual(weekly.when, ThingsWhen.today)

        let monthly = plan("Pay rent monthly")
        XCTAssertEqual(monthly.repeatRule, ThingsNaturalLanguageRepeat(repeatAfter: 0, repeatMode: 1))

        let every = plan("Backup every 2 days")
        XCTAssertEqual(every.repeatRule, ThingsNaturalLanguageRepeat(repeatAfter: 172_800, repeatMode: 0))
        XCTAssertEqual(every.title, "Backup")

        let other = plan("Clean every other week")
        XCTAssertEqual(other.repeatRule, ThingsNaturalLanguageRepeat(repeatAfter: 1_209_600, repeatMode: 0))
    }

    func testEveryWeekdayRepeatsWeeklyFromThatDay() {
        let result = plan("Gym every monday")
        XCTAssertEqual(result.title, "Gym")
        XCTAssertEqual(result.repeatRule, ThingsNaturalLanguageRepeat(repeatAfter: 604_800, repeatMode: 0))
        XCTAssertEqual(result.when, ThingsWhen.date(date(2026, 11, 23)))
    }

    // MARK: - French

    func testFrenchDays() {
        let tomorrow = plan("Appeler Paul demain")
        XCTAssertEqual(tomorrow.title, "Appeler Paul")
        XCTAssertEqual(tomorrow.when, ThingsWhen.date(date(2026, 11, 17)))

        XCTAssertEqual(plan("Payer aujourd'hui").when, ThingsWhen.today)
        XCTAssertEqual(plan("Dentiste après-demain").when, ThingsWhen.date(date(2026, 11, 18)))
        XCTAssertEqual(plan("Relancer dans 3 jours").when, ThingsWhen.date(date(2026, 11, 19)))
        XCTAssertEqual(plan("Relancer dans 3 jours").title, "Relancer")
    }

    func testFrenchWeekdayWithATime() {
        let result = plan("Réunion lundi prochain à 14h")
        XCTAssertEqual(result.title, "Réunion")
        XCTAssertEqual(result.when, ThingsWhen.date(date(2026, 11, 23)))
        XCTAssertEqual(result.reminder, date(2026, 11, 23, 14, 0))
    }

    func testFrenchEveningAndNoon() {
        let evening = plan("Dîner demain soir")
        XCTAssertEqual(evening.title, "Dîner")
        XCTAssertEqual(evening.when, ThingsWhen.date(date(2026, 11, 17)))
        XCTAssertEqual(evening.reminder, date(2026, 11, 17, 19, 0))

        let noon = plan("Déjeuner demain à midi")
        XCTAssertEqual(noon.reminder, date(2026, 11, 17, 12, 0))
    }

    func testFrenchThisEveningAndSomeday() {
        let tonight = plan("Appeler Paul ce soir")
        XCTAssertEqual(tonight.title, "Appeler Paul")
        XCTAssertEqual(tonight.when, ThingsWhen.thisEvening)

        let someday = plan("Apprendre le piano un jour")
        XCTAssertEqual(someday.title, "Apprendre le piano")
        XCTAssertEqual(someday.when, ThingsWhen.someday)
    }

    func testFrenchDateAndDeadline() {
        let birthday = plan("Anniversaire le 15 avril")
        XCTAssertEqual(birthday.title, "Anniversaire")
        XCTAssertEqual(birthday.when, ThingsWhen.date(date(2027, 4, 15)))

        let report = plan("Envoyer le rapport avant le 15 décembre")
        XCTAssertEqual(report.title, "Envoyer le rapport")
        XCTAssertEqual(report.deadline, date(2026, 12, 15, 12, 0))
        XCTAssertNil(report.when)
    }

    func testFrenchNextWeekIsAFutureDay() {
        let result = plan("Bilan la semaine prochaine")
        XCTAssertEqual(result.title, "Bilan")
        if case .date(let day)? = result.when {
            XCTAssertGreaterThan(day, date(2026, 11, 16))
        } else {
            XCTFail("expected a future day")
        }
    }

    func testFrenchRepeat() {
        let biweekly = plan("Arroser les plantes toutes les 2 semaines")
        XCTAssertEqual(biweekly.title, "Arroser les plantes")
        XCTAssertEqual(biweekly.repeatRule, ThingsNaturalLanguageRepeat(repeatAfter: 1_209_600, repeatMode: 0))

        let monthly = plan("Loyer chaque mois")
        XCTAssertEqual(monthly.repeatRule, ThingsNaturalLanguageRepeat(repeatAfter: 0, repeatMode: 1))

        let daily = plan("Marcher tous les jours")
        XCTAssertEqual(daily.repeatRule, ThingsNaturalLanguageRepeat(repeatAfter: 86_400, repeatMode: 0))
    }

    func testFrenchWordAfterASigilStaysAName() {
        let demain = SmartTaskParser.Candidate(id: 20, name: "Demain")
        let result = mapper(extraProjects: [demain]).plan(for: "Plan +Demain")
        XCTAssertEqual(result.projectID, 20)
        XCTAssertEqual(result.title, "Plan")
        XCTAssertNil(result.when)
    }

    func testFrenchDurationIsNotATime() {
        let result = plan("Réunion de 2h")
        XCTAssertEqual(result.title, "Réunion de 2h")
        XCTAssertNil(result.reminder)
    }

    func testAnImpossibleFrenchDateKeepsTheTypedTitle() {
        let result = plan("Fête le 31 février")
        XCTAssertEqual(result.title, "Fête le 31 février")
        XCTAssertNil(result.when)
    }

    // MARK: - Models

    func testModelInitSkipsReservedTagsAndKeepsRealOnes() {
        let built = ThingsNaturalLanguage(
            projectModels: [Project(id: 1, title: "Home")],
            labelModels: [VLabel(id: 1, title: ThingsReservedLabels.someday), VLabel(id: 2, title: "urgent")],
            now: now,
            calendar: utc,
            locale: Locale(identifier: "en_GB"),
            defaultDueTime: .sixPM,
            usesDataDetector: false
        )
        let result = built.plan(for: "Fix tap +Home *urgent *things:someday")
        XCTAssertEqual(result.projectID, 1)
        XCTAssertEqual(result.labelIDs, [2])
    }

    // MARK: - Chips

    func testChipsFollowThePreviewOrder() {
        let result = plan("Buy milk tomorrow +Home *urgent !2 ~30m by friday")
        XCTAssertEqual(result.title, "Buy milk")
        let chips = result.chips(now: now, calendar: utc, locale: Locale(identifier: "en_GB"))
        XCTAssertEqual(chips.map { $0.kind }, [.when, .deadline, .project, .tag, .priority, .estimate])
        XCTAssertEqual(chips.first(where: { $0.kind == .project })?.text, "Home")
        XCTAssertEqual(chips.first(where: { $0.kind == .tag })?.text, "urgent")
        XCTAssertEqual(chips.first(where: { $0.kind == .estimate })?.text, "30 min")
    }

    func testNoChipsForAPlainTitle() {
        let chips = plan("Buy milk").chips(now: now, calendar: utc, locale: Locale(identifier: "en_GB"))
        XCTAssertTrue(chips.isEmpty)
    }

    func testEstimateText() {
        XCTAssertEqual(ThingsNaturalLanguagePlan.estimateText(1800), "30 min")
        XCTAssertEqual(ThingsNaturalLanguagePlan.estimateText(3600), "1 h")
        XCTAssertEqual(ThingsNaturalLanguagePlan.estimateText(5400), "1 h 30")
    }
}
