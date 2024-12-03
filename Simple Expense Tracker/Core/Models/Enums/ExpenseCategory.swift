import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable {
    case general = "General"
    case housing = "Housing"
    case mobility = "Mobility"
    case utilities = "Utilities"
    case entertainment = "Entertainment"
    case groceries = "Groceries"
    case eatingOut = "Eating Out"
    case health = "Health"
    case clothing = "Clothing"
    case insurance = "Insurance"
    case education = "Education"
    case kids = "Kids"
    case tech = "Tech"
    case travel = "Travel"
    case taxes = "Taxes"
    case gifts = "Gifts"
    
    var icon: String {
        switch self {
        case .general: return "tag"
        case .housing: return "house"
        case .mobility: return "car"
        case .utilities: return "bolt.fill"
        case .entertainment: return "headphones"
        case .groceries: return "cart"
        case .eatingOut: return "fork.knife"
        case .health: return "heart.text.square"
        case .clothing: return "tshirt"
        case .insurance: return "shield"
        case .education: return "brain.head.profile"
        case .kids: return "face.smiling"
        case .tech: return "laptopcomputer.and.iphone"
        case .travel: return "airplane"
        case .taxes: return "building.columns"
        case .gifts: return "gift"
        }
    }
    
    var localizedName: String {
        return self.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized
    }
} 