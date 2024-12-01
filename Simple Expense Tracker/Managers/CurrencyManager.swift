//
//  CurrencyManager.swift
//  Simple Expense Tracker
//
//  Created by Mucahit Bilal GOKER on 1.12.2024.
//

import Foundation

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var currentCurrency: Currency {
        didSet {
            UserDefaults.standard.set(currentCurrency.rawValue, forKey: "AppCurrency")
        }
    }
    
    private init() {
        let savedCurrency = UserDefaults.standard.string(forKey: "AppCurrency") ?? Currency.trl.rawValue
        currentCurrency = Currency(rawValue: savedCurrency) ?? .trl
    }
}
