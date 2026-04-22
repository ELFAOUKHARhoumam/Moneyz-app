import Foundation

struct DateRangeService {
    static func interval(
        for option: TimeRangeOption,
        reference: Date = .now,
        salaryCycleStartDay: Int,
        calendar: Calendar = .current
    ) -> DateInterval {
        switch option {
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: reference)) ?? reference
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? reference
            return DateInterval(start: start, end: end)
        case .year:
            let start = calendar.date(from: calendar.dateComponents([.year], from: reference)) ?? reference
            let end = calendar.date(byAdding: .year, value: 1, to: start) ?? reference
            return DateInterval(start: start, end: end)
        case .salaryCycle:
            return salaryCycleInterval(reference: reference, cycleStartDay: salaryCycleStartDay, calendar: calendar)
        }
    }

    static func salaryCycleInterval(reference: Date, cycleStartDay: Int, calendar: Calendar = .current) -> DateInterval {
        let startThisMonth = anchoredDate(day: cycleStartDay, in: reference, calendar: calendar)
        if reference >= startThisMonth {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startThisMonth) ?? reference
            let end = anchoredDate(day: cycleStartDay, in: nextMonth, calendar: calendar)
            return DateInterval(start: startThisMonth, end: end)
        } else {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: startThisMonth) ?? reference
            let start = anchoredDate(day: cycleStartDay, in: previousMonth, calendar: calendar)
            return DateInterval(start: start, end: startThisMonth)
        }
    }

    static func contains(_ date: Date, in interval: DateInterval) -> Bool {
        date >= interval.start && date < interval.end
    }

    static func anchoredDate(day: Int, in referenceMonth: Date, calendar: Calendar = .current) -> Date {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceMonth)) ?? referenceMonth
        let validRange = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<29
        let clampedDay = max(validRange.lowerBound, min(day, validRange.upperBound - 1))
        var components = calendar.dateComponents([.year, .month], from: monthStart)
        components.day = clampedDay
        return calendar.date(from: components) ?? monthStart
    }
}
