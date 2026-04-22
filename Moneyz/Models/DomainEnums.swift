import Foundation

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }
    var multiplier: Int64 { self == .expense ? -1 : 1 }

    var localizedKey: String {
        switch self {
        case .expense: return "transaction.kind.expense"
        case .income: return "transaction.kind.income"
        }
    }
}

enum CategoryKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case both

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .expense: return "category.kind.expense"
        case .income: return "category.kind.income"
        case .both: return "category.kind.both"
        }
    }
}

enum BudgetPeriod: String, Codable, CaseIterable, Identifiable {
    case month
    case year
    case salaryCycle

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .month: return "time.month"
        case .year: return "time.year"
        case .salaryCycle: return "time.salaryCycle"
        }
    }
}

enum DebtDirection: String, Codable, CaseIterable, Identifiable {
    case iOwe
    case owedToMe

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .iOwe: return "debt.direction.iOwe"
        case .owedToMe: return "debt.direction.owedToMe"
        }
    }
}

enum DebtStatus: String, Codable, CaseIterable, Identifiable {
    case open
    case partial
    case settled

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .open: return "status.open"
        case .partial: return "status.partial"
        case .settled: return "status.settled"
        }
    }
}

enum RecurringFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .weekly: return "frequency.weekly"
        case .monthly: return "frequency.monthly"
        case .yearly: return "frequency.yearly"
        }
    }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

enum TimeRangeOption: String, CaseIterable, Identifiable {
    case month
    case year
    case salaryCycle

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .month: return "time.month"
        case .year: return "time.year"
        case .salaryCycle: return "time.salaryCycle"
        }
    }
}

enum SyncAvailabilityStatus: Equatable {
    case checking
    case available
    case unavailable
    case noAccount
    case restricted
    case temporarilyUnavailable
    case notConfigured
    case error(String)

    var titleKey: String {
        switch self {
        case .checking: return "sync.checking"
        case .available: return "sync.available"
        case .unavailable: return "sync.unavailable"
        case .noAccount: return "sync.noAccount"
        case .restricted: return "sync.restricted"
        case .temporarilyUnavailable: return "sync.temporarilyUnavailable"
        case .notConfigured: return "sync.notConfigured"
        case .error: return "sync.error"
        }
    }

    var detail: String? {
        switch self {
        case .notConfigured:
            return AppLocalizer.string("sync.notConfigured.detail")
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}
