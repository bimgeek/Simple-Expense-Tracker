import Foundation

enum SortOption: String, CaseIterable {
    case date = "Date"
    case amount = "Amount"
    
    var icon: String {
        switch self {
        case .date: return "calendar"
        case .amount: return "banknote"
        }
    }
    
    var localizedLabel: String {
        switch self {
        case .date: return "sort_by_date".localized
        case .amount: return "sort_by_amount".localized
        }
    }
} 
