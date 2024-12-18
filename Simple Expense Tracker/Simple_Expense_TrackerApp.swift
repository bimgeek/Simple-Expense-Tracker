//
//  Simple_Expense_TrackerApp.swift
//  Simple Expense Tracker
//
//  Created by Mucahit Bilal GOKER on 24.11.2024.
//

import SwiftUI
import GoogleMobileAds

@main
struct Simple_Expense_TrackerApp: App {
    init() {
        // Initialize Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
