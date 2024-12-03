import SwiftUI

enum DateOption: Equatable {
    case yesterday
    case today
    case custom(Date)
    
    static func == (lhs: DateOption, rhs: DateOption) -> Bool {
        switch (lhs, rhs) {
        case (.yesterday, .yesterday):
            return true
        case (.today, .today):
            return true
        case (.custom(let date1), .custom(let date2)):
            return Calendar.current.isDate(date1, inSameDayAs: date2)
        default:
            return false
        }
    }
    
    var date: Date {
        switch self {
        case .yesterday:
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .today:
            return Date()
        case .custom(let date):
            return date
        }
    }
}

// Add TabSelection enum at the top level, next to DateOption
enum TabSelection {
    case home, log, insights, settings
}

enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case trl = "TRL"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .trl: return "₺"
        }
    }
    
    var localizedName: String {
        rawValue.lowercased().localized
    }
}