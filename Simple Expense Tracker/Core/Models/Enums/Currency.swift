import SwiftUI

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