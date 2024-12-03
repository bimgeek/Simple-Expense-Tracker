//
//  ContentView.swift
//  Simple Expense Tracker
//
//  Created by Mucahit Bilal GOKER on 24.11.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var expenseManager = ExpenseManager()
    @State private var showingAddExpense = false
    @State private var selectedTab: TabSelection = .home
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 0.05, green: 0.05, blue: 0.2)
                .ignoresSafeArea()
            
            // Main content based on selected tab
            Group {
                switch selectedTab {
                case .home:
                    HomeView(expenseManager: expenseManager, selectedTab: $selectedTab)
                        .transition(.opacity)
                case .log:
                    LogView(expenseManager: expenseManager)
                        .transition(.opacity)
                case .insights:
                    InsightsView(expenseManager: expenseManager)
                        .transition(.opacity)
                case .settings:
                    SettingsView(expenseManager: expenseManager)
                        .preferredColorScheme(.dark)  // Force dark mode
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: selectedTab)
            
            // Add Button (only show on home tab)
            if selectedTab == .home {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddExpense = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.black)
                                .frame(width: 55, height: 55)
                                .background(Color.cyan)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 70)
                    }
                }
            }
            
            // Tab bar at bottom
            VStack(spacing: 0) {
                Spacer()
                // Tab bar
                HStack {
                    TabBarItem(icon: "house.fill", text: "home".localized,
                             isSelected: selectedTab == .home)
                        .onTapGesture { selectedTab = .home }
                    Spacer()
                    TabBarItem(icon: "calendar", text: "log".localized,
                             isSelected: selectedTab == .log)
                        .onTapGesture { selectedTab = .log }
                    Spacer()
                    TabBarItem(icon: "chart.pie", text: "insights".localized,
                             isSelected: selectedTab == .insights)
                        .onTapGesture { selectedTab = .insights }
                    Spacer()
                    TabBarItem(icon: "gearshape", text: "settings".localized,
                             isSelected: selectedTab == .settings)
                        .onTapGesture { selectedTab = .settings }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .background(
                    Color(red: 0.05, green: 0.05, blue: 0.2)
                        .opacity(0.95)
                        .ignoresSafeArea(edges: .bottom)
                )
                // Add top border
                .overlay(
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity)
                    , alignment: .top
                )
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(isPresented: $showingAddExpense, expenseManager: expenseManager)
        }
    }
}



#Preview {
    ContentView()
}
