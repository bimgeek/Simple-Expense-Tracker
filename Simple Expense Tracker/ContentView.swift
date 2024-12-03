//
//  ContentView.swift
//  Simple Expense Tracker
//
//  Created by Mucahit Bilal GOKER on 24.11.2024.
//

import SwiftUI

// Add this enum definition at the top level, before ContentView
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

// First, let's create a separate view for the month selector
struct MonthSelectorView: View {
    let monthYearString: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    @StateObject private var currencyManager = CurrencyManager.shared

    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.cyan)
                    .font(.title3)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .foregroundColor(.cyan)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.cyan)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
}

// Create a view for the day's expenses
struct DayExpensesView: View {
    let day: String
    let expenses: [Expense]
    let dayTotal: Double
    @ObservedObject var expenseManager: ExpenseManager
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day)
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(currencyManager.currentCurrency.symbol)\(dayTotal, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            ForEach(expenses) { expense in
                ExpenseRow(expense: expense, expenseManager: expenseManager)
            }
        }
    }
}

// Create a view for the monthly total
struct MonthlyTotalView: View {
    let total: Double
    
    @StateObject private var currencyManager = CurrencyManager.shared

    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                Text("monthly_total".localized)
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(currencyManager.currentCurrency.symbol)\(total, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color(red: 0.05, green: 0.05, blue: 0.2).opacity(0.95))
        }
        .padding(.bottom, 49)
    }
}

struct TabBarItem: View {
    let icon: String
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(text)
                .font(.caption)
        }
        .foregroundColor(isSelected ? .cyan : .gray)
    }
}

// First, update ExpenseRow to be tappable and show details
struct ExpenseRow: View {
    let expense: Expense
    @ObservedObject var expenseManager: ExpenseManager
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line
    @State private var showingExpenseDetails = false
    @State private var showingDeleteConfirmation = false  // Add this
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        // Set locale based on selected language
        switch LanguageManager.shared.currentLanguage {
        case .turkish:
            formatter.locale = Locale(identifier: "tr")
        case .english:
            formatter.locale = Locale(identifier: "en")
        case .system:
            formatter.locale = Locale.current
        }
        return formatter.string(from: expense.date)
    }
    
    var body: some View {
        Button(action: {
            showingExpenseDetails = true
        }) {
            HStack(spacing: 12) {
                // Category Icon
                Image(systemName: expense.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(categoryColor(for: expense.category))
                    .clipShape(Circle())
                
                // Expense Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.memo.isEmpty ? expense.category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized : expense.memo)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("\(formattedTime)")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                // Amount
                Text("-\(currencyManager.currentCurrency.symbol)\(expense.amount, specifier: "%.2f")")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingExpenseDetails) {
            ExpenseDetailsEditView(
                expense: expense,
                expenseManager: expenseManager,
                isPresented: $showingExpenseDetails
            )
        }
    }
    
    private func categoryColor(for category: ExpenseCategory) -> Color {
        switch category {
        case .general: return .cyan
        case .housing: return .blue
        case .mobility: return .green
        case .utilities: return .yellow
        case .entertainment: return .purple
        case .groceries: return .orange
        case .eatingOut: return .pink
        case .health: return .red
        case .clothing: return .indigo
        case .insurance: return .mint
        case .education: return .teal
        case .kids: return .cyan.opacity(0.7)
        case .tech: return .blue.opacity(0.7)
        case .travel: return .green.opacity(0.7)
        case .taxes: return .yellow.opacity(0.7)
        case .gifts: return .purple.opacity(0.7)
        }
    }
}

struct AddExpenseView: View {
    @Binding var isPresented: Bool
    @ObservedObject var expenseManager: ExpenseManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                    ForEach(ExpenseCategory.allCases.reversed(), id: \.self) { category in
                        NavigationLink(destination: ExpenseDetailsView(
                            category: category,
                            expenseManager: expenseManager,
                            isPresented: $isPresented
                        )) {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(categoryColor(for: category))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: category.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }
                                
                                Text(category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("add_expense".localized)
            .navigationBarItems(
                leading: Button("cancel".localized) {
                    isPresented = false
                }
            )
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    private func categoryColor(for category: ExpenseCategory) -> Color {
        switch category {
        case .general: return .cyan
        case .housing: return .blue
        case .mobility: return .green
        case .utilities: return .yellow
        case .entertainment: return .purple
        case .groceries: return .orange
        case .eatingOut: return .pink
        case .health: return .red
        case .clothing: return .indigo
        case .insurance: return .mint
        case .education: return .teal
        case .kids: return .cyan.opacity(0.7)
        case .tech: return .blue.opacity(0.7)
        case .travel: return .green.opacity(0.7)
        case .taxes: return .yellow.opacity(0.7)
        case .gifts: return .purple.opacity(0.7)
        }
    }
}

// Add this new view for memo suggestions
struct MemoSuggestionView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { memo in
                    Button(action: { onSelect(memo) }) {
                        Text(memo)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: suggestions.isEmpty ? 0 : 44)
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

// Create a separate view for the category legend
struct CategoryLegendView: View {
    let categories: [(category: ExpenseCategory, amount: Double)]
    let total: Double
    let categoryColor: (ExpenseCategory) -> Color
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(categories, id: \.category) { item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(categoryColor(item.category))
                        .frame(width: 12, height: 12)
                    
                    Text(item.category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(item.amount, specifier: "%.2f")")
                        .foregroundColor(.gray)
                    
                    Text("(\(Int((item.amount / total) * 100))%")
                        .foregroundColor(.gray)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, -8)
    }
}

// Add this helper view for the comparison indicator
struct MonthComparisonView: View {
    let currentAmount: Double
    let previousAmount: Double
    
    private var percentageChange: Double {
        guard previousAmount > 0 else { return 0 }
        return ((currentAmount - previousAmount) / previousAmount) * 100
    }
    
    private var isIncrease: Bool {
        currentAmount > previousAmount
    }
    
    var body: some View {
        if previousAmount > 0 {
            HStack(spacing: 4) {
                Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(isIncrease ? .red : .green)
                
                Text("\(abs(percentageChange), specifier: "%.1f")%")
                    .foregroundColor(isIncrease ? .red : .green)
                    .font(.system(size: 14, weight: .medium))
                
                Text("vs last month")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
}

// Add these new components
struct DayHeatmapCell: View {
    let date: Date
    let amount: Double
    let maxAmount: Double
    @State private var isShowingAmount = false
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line

    
    private var opacity: Double {
        guard amount > 0 else { return 0.1 }
        return 0.2 + min(0.8, (amount / maxAmount) * 0.8)
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.red.opacity(opacity))
            .frame(height: 30)
            .cornerRadius(6)
            .overlay(
                isShowingAmount ? Text("\(currencyManager.currentCurrency.symbol)\(amount, specifier: "%.0f")")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    : nil
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingAmount.toggle()
                }
            }
    }
}

struct ExpenseHeatmapView: View {
    let expenses: [Expense]
    let currentDate: Date
    
    private var daysInMonth: Int {
        let calendar = Calendar.current
        if let range = calendar.range(of: .day, in: .month, for: currentDate) {
            return range.count
        }
        return 0
    }
    
    private var firstDayOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        return calendar.date(from: components) ?? currentDate
    }
    
    private var firstWeekday: Int {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: firstDayOfMonth)
    }
    
    private var weeksInMonth: Int {
        let firstDayWeekday = firstWeekday
        return Int(ceil((Double(firstDayWeekday - 1 + daysInMonth)) / 7.0))
    }
    
    private func dayForCell(week: Int, weekday: Int) -> Int? {
        // weekday parameter is 0-6 (Sunday-Saturday)
        // firstWeekday is 1-7 (Sunday-Saturday)
        let adjustedWeekday = weekday + 1  // Convert to 1-based weekday
        let day = (week * 7) + adjustedWeekday - firstWeekday + 1
        
        if day > 0 && day <= daysInMonth {
            return day
        }
        return nil
    }
    
    private func expenseForDay(_ day: Int) -> Double {
        let calendar = Calendar.current
        let dayStart = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) ?? Date()
        
        return expenses.filter { expense in
            calendar.isDate(expense.date, inSameDayAs: dayStart)
        }.reduce(0) { $0 + $1.amount }
    }
    
    private func cellColor(_ amount: Double) -> Color {
        let maxAmount = expenses.map { $0.amount }.max() ?? 0
        let normalizedAmount = maxAmount > 0 ? amount / maxAmount : 0
        return Color.red.opacity(normalizedAmount * 0.8 + 0.1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("spending_heatmap".localized)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                ForEach(0..<weeksInMonth, id: \.self) { week in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { weekday in
                            if let day = dayForCell(week: week, weekday: weekday) {
                                let amount = expenseForDay(day)
                                HeatmapCell(
                                    day: day,
                                    amount: amount,
                                    maxAmount: expenses.map { $0.amount }.max() ?? 0
                                )
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// Add this new component for statistics cards
struct StatisticCardView: View {
    let title: String
    let amount: Double
    let icon: String
    @StateObject private var currencyManager = CurrencyManager.shared

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                Text(title)
                    .foregroundColor(.gray)
            }
            .font(.system(size: 14))
            
            Text("\(currencyManager.currentCurrency.symbol)\(amount, specifier: "%.2f")")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// Add this view to group the statistics cards
struct MonthlyStatisticsView: View {
    let expenses: [Expense]
    let currentDate: Date
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 0
    }
    
    private var weeksInMonth: Int {
        let weeks = calendar.range(of: .weekOfMonth, in: .month, for: currentDate)?.count ?? 0
        return max(1, weeks)
    }
    
    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var averageDailyExpense: Double {
        totalAmount / Double(daysInMonth)
    }
    
    private var averageWeeklyExpense: Double {
        totalAmount / Double(weeksInMonth)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("monthly_statistics".localized)
                .font(.headline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                StatisticCardView(
                    title: "daily_average".localized,
                    amount: averageDailyExpense,
                    icon: "clock"
                )
                
                StatisticCardView(
                    title: "weekly_average".localized,
                    amount: averageWeeklyExpense,
                    icon: "calendar.badge.clock"
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// Add this new component for the line chart
struct WeeklyExpenseChartView: View {
    let expenses: [Expense]
    let currentDate: Date
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line

    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private struct WeekData: Identifiable {
        let id = UUID()
        let weekNumber: Int
        let amount: Double
        let weekStart: Date
    }
    
    private var weeklyData: [WeekData] {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let range = calendar.range(of: .weekOfMonth, in: .month, for: currentDate)
        else { return [] }
        
        var result: [WeekData] = []
        
        for weekNumber in range {
            guard let weekStart = calendar.date(from: DateComponents(
                year: components.year,
                month: components.month,
                weekday: 1,  // Sunday
                weekOfMonth: weekNumber
            )) else { continue }
            
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            
            let weekExpenses = expenses.filter { expense in
                expense.date >= weekStart && expense.date < weekEnd
            }
            
            let total = weekExpenses.reduce(0) { $0 + $1.amount }
            result.append(WeekData(weekNumber: weekNumber, amount: total, weekStart: weekStart))
        }
        
        return result
    }
    
    private var maxAmount: Double {
        weeklyData.map { $0.amount }.max() ?? 0
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("weekly_trend".localized)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                // Line Chart
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        // Draw the line chart
                        Path { path in
                            guard !weeklyData.isEmpty else { return }
                            
                            let width = geometry.size.width / CGFloat(weeklyData.count - 1)
                            let height = geometry.size.height - 40 // Leave space for labels
                            
                            var startPoint = true
                            
                            for data in weeklyData {
                                let x = CGFloat(data.weekNumber - 1) * width
                                let y = height - (height * (data.amount / maxAmount))
                                
                                if startPoint {
                                    path.move(to: CGPoint(x: x, y: y))
                                    startPoint = false
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.cyan, lineWidth: 2)
                        
                        // Draw amount labels and dots
                        ForEach(weeklyData) { data in
                            let width = geometry.size.width / CGFloat(weeklyData.count - 1)
                            let height = geometry.size.height - 40
                            let x = CGFloat(data.weekNumber - 1) * width
                            let y = height - (height * (data.amount / maxAmount))
                            
                            // Data point dot
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                            
                            // Amount label
                            Text("\(currencyManager.currentCurrency.symbol)\(data.amount, specifier: "%.0f")")
                                .font(.system(size: 12, weight: .medium)) // Increased size and added weight
                                .foregroundColor(.white) // Changed to white for better contrast
                                .background(Color.black.opacity(0.7))
                                .padding(.horizontal, 6) // Increased horizontal padding
                                .padding(.vertical, 3) // Increased vertical padding
                                .cornerRadius(4)
                                .position(x: x, y: max(25, y - 25)) // Adjusted spacing to accommodate larger text
                            
                            // Date label
                            Text(dateFormatter.string(from: data.weekStart))
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                                .position(x: x, y: height + 20)
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// Add new ExpenseDetailsEditView
struct ExpenseDetailsEditView: View {
    let expense: Expense
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line
    
    @State private var amount: String = ""
    @State private var memo: String = ""
    @State private var selectedDateOption: DateOption = .today
    @State private var vatAmount: String = ""
    @State private var showingDatePicker = false
    @State private var showingDeleteAlert = false
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isVATFocused: Bool
    @FocusState private var isMemoFocused: Bool
    @State private var receiptImage: UIImage?
    @State private var showingCamera = false
    @State private var showingFullScreenImage = false
    @State private var shouldDeleteImage = false
    @State private var showMemoSuggestions = false  // Add this line
    
    // Add category property
    private let category: ExpenseCategory
    
    init(expense: Expense, expenseManager: ExpenseManager, isPresented: Binding<Bool>) {
        self.expense = expense
        self.expenseManager = expenseManager
        self._isPresented = isPresented
        self.category = expense.category  // Initialize category from expense
        
        // Initialize state with expense values
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _vatAmount = State(initialValue: String(format: "%.2f", expense.vat))
        _memo = State(initialValue: expense.memo)
        _selectedDateOption = State(initialValue: .custom(expense.date))
    }
    
    private func formatNumberString(_ input: String) -> String {
        let sanitized = input.replacingOccurrences(of: ",", with: ".")
        let components = sanitized.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        return sanitized
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDateOption.date)
    }
    
    private var memoSuggestions: [String] {
        guard !memo.isEmpty else { return [] }
        return expenseManager.previousMemos(for: category, startingWith: memo)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.01)
                    .onTapGesture {
                        isAmountFocused = false
                        isVATFocused = false
                        isMemoFocused = false
                    }
                
                VStack(spacing: 24) {
                    // Category Chip
                    HStack(spacing: 8) {
                        Image(systemName: expense.category.icon)
                        Text(expense.category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.top)
                    
                    // Amount Input
                    VStack(spacing: 16) {
                        ZStack {
                            HStack(spacing: 4) {
                                Text(currencyManager.currentCurrency.symbol)
                                    .font(.system(size: 72, weight: .regular))
                                TextField("0", text: Binding(
                                    get: { amount },
                                    set: { amount = formatNumberString($0) }
                                ))
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 72, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.5)
                                    .frame(maxWidth: 400)
                                    .focused($isAmountFocused)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .padding(.horizontal, 20)
                        
                        // VAT Input
                        TextField("vat".localized, text: Binding(
                            get: { vatAmount },
                            set: { vatAmount = formatNumberString($0) }
                        ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .focused($isVATFocused)
                        
                        // Memo Input
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("memo".localized, text: $memo)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .focused($isMemoFocused)
                                .onChange(of: memo) { _, newValue in
                                    showMemoSuggestions = !newValue.isEmpty
                                }
                            
                            // Add MemoSuggestionView if there are suggestions
                            if showMemoSuggestions && !memoSuggestions.isEmpty {
                                MemoSuggestionView(
                                    suggestions: memoSuggestions,
                                    onSelect: { selectedMemo in
                                        memo = selectedMemo
                                        showMemoSuggestions = false
                                    }
                                )
                            }
                        }
                        
                        // Date Selection
                        HStack {
                            Text("date".localized + ":")
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                Text(formattedDate)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Receipt Image Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("receipt".localized)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            if let image = receiptImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                    .overlay(
                                        Button(action: { receiptImage = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .padding(8)
                                        }
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(8),
                                        alignment: .topTrailing
                                    )
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        showingFullScreenImage = true
                                    }
                            }
                            
                            Button(action: {
                                showingCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text(receiptImage == nil ? "take_photo".localized : "retake_photo".localized)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.0, green: 0.478, blue: 1.0))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarItems(
                leading: Button("delete".localized) {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red),
                trailing: Button("done".localized) {
                    // Add this code to save changes
                    if let amountDouble = Double(amount),
                       let vatDouble = Double(vatAmount) {
                        // Save image if exists
                        var imagePath = expense.receiptImagePath
                        if let image = receiptImage {
                            imagePath = ImageManager.shared.saveImage(image, forExpense: expense.id)
                        }
                        
                        expenseManager.updateExpense(
                            expense,
                            newAmount: amountDouble,
                            newVat: vatDouble,
                            newMemo: memo,
                            newDate: selectedDateOption.date,
                            receiptImagePath: imagePath
                        )
                    }
                    isPresented = false
                }
            )
            .alert("delete_expense".localized, isPresented: $showingDeleteAlert) {
                Button("cancel".localized, role: .cancel) { }
                Button("delete".localized, role: .destructive) {
                    expenseManager.deleteExpense(expense)
                    isPresented = false
                }
            } message: {
                Text("delete_expense_warning".localized)
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationView {
                    DatePicker("", selection: Binding(
                        get: {
                            if case .custom(let date) = selectedDateOption {
                                return date
                            }
                            return Date()
                        },
                        set: { newDate in
                            selectedDateOption = .custom(newDate)
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .navigationBarItems(
                        trailing: Button("done".localized) {
                            showingDatePicker = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $receiptImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingFullScreenImage) {
                if let image = receiptImage {
                    FullScreenImageView(
                        image: image,
                        isPresented: $showingFullScreenImage,
                        shouldDeleteImage: $shouldDeleteImage
                    )
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .onChange(of: shouldDeleteImage) { _, shouldDelete in
                if shouldDelete {
                    receiptImage = nil
                }
            }
            .onAppear {
                if let imagePath = expense.receiptImagePath {
                    receiptImage = ImageManager.shared.loadImage(filename: imagePath)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
