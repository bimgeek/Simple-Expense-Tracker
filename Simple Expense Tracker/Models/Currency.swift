//
//  Currency.swift
//  Simple Expense Tracker
//
//  Created by Mucahit Bilal GOKER on 1.12.2024.
//
import Foundation

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
