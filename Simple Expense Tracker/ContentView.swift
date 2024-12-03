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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ExportPickerView: View {
    @Binding var date: Date
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    @State private var csvURL: URL?
    
    private let months = Calendar.current.monthSymbols
    private let years = Array(2020...2030)
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                // Month Menu
                Menu {
                    ForEach(months.indices, id: \.self) { index in
                        Button(action: {
                            let year = Calendar.current.component(.year, from: date)
                            let components = DateComponents(year: year, month: index + 1, day: 1)
                            if let newDate = Calendar.current.date(from: components) {
                                date = newDate
                            }
                        }) {
                            Text(months[index])
                        }
                    }
                } label: {
                    HStack {
                        Text(months[Calendar.current.component(.month, from: date) - 1])
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .frame(width: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                
                // Year Menu
                Menu {
                    ForEach(years, id: \.self) { year in
                        Button(action: {
                            let month = Calendar.current.component(.month, from: date)
                            let components = DateComponents(year: year, month: month, day: 1)
                            if let newDate = Calendar.current.date(from: components) {
                                date = newDate
                            }
                        }) {
                            Text(String(format: "%d", year))
                        }
                    }
                } label: {
                    HStack {
                        Text(String(format: "%d", Calendar.current.component(.year, from: date)))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .frame(width: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .navigationTitle("Export Expenses")
        .navigationBarItems(
            leading: Button("Cancel") {
                isPresented = false
            },
            trailing: Button("Export") {
                if let url = generateCSV() {
                    presentShareSheet(url: url)
                }
            }
        )
    }
    
    private func presentShareSheet(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() else { return }
        
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            // Clean up the temporary file
            try? FileManager.default.removeItem(at: url)
        }
        
        viewController.present(activityVC, animated: true)
    }
    
    private func generateCSV() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        // Get the month's expenses
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let monthExpenses = expenseManager.expenses.filter { expense in
            let components = calendar.dateComponents([.month, .year], from: expense.date)
            return components.month == month && components.year == year
        }
        
        // Create CSV content
        var csvContent = "Date,Category,Amount,VAT,Memo\n"
        
        for expense in monthExpenses.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: expense.date)
            let category = expense.category.rawValue
            let amount = String(format: "%.2f", expense.amount)
            let vat = String(format: "%.2f", expense.vat)
            let memo = expense.memo.replacingOccurrences(of: ",", with: ";") // Escape commas in memo
            
            csvContent += "\(date),\(category),\(amount),\(vat),\(memo)\n"
        }
        
        // Create temporary file
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM_yyyy"
        let fileName = "expenses_\(formatter.string(from: date)).csv"
        
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV file: \(error)")
            return nil
        }
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        
        return self
    }
}

// Add this new component for the line chart


#Preview {
    ContentView()
}
