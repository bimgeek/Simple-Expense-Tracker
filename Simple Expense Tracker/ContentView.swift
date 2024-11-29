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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day)
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("₺\(dayTotal, specifier: "%.2f")")
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
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                Text("monthly_total".localized)
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("₺\(total, specifier: "%.2f")")
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

// Now update the LogView to use these components
struct LogView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @State private var selectedDate = Date()
    @State private var slideDirection: SlideDirection = .none
    @State private var filterOptions = FilterOptions()
    @State private var showingMemoSearch = false
    
    private enum SlideDirection {
        case left, right, none
    }
    
    private var groupedExpenses: [(String, [(String, [Expense], Double)])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMMM"
        // Add these lines to set locale based on selected language
        switch LanguageManager.shared.currentLanguage {
        case .turkish:
            formatter.locale = Locale(identifier: "tr")
            dayFormatter.locale = Locale(identifier: "tr")
        case .english:
            formatter.locale = Locale(identifier: "en")
            dayFormatter.locale = Locale(identifier: "en")
        case .system:
            formatter.locale = Locale.current
            dayFormatter.locale = Locale.current
        }
        
        // Filter expenses for selected month
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)
        
        let filteredExpenses = expenseManager.expenses.filter { expense in
            // First filter by month/year
            let components = calendar.dateComponents([.month, .year], from: expense.date)
            guard components.month == selectedMonth && components.year == selectedYear else {
                return false
            }
            
            // Apply category filter
            if !filterOptions.selectedCategories.isEmpty && 
               !filterOptions.selectedCategories.contains(expense.category) {
                return false
            }
            
            // Apply memo search
            if !filterOptions.memoSearch.isEmpty && 
               !expense.memo.localizedCaseInsensitiveContains(filterOptions.memoSearch) {
                return false
            }
            
            // Apply VAT filter
            if filterOptions.showMissingVAT && expense.vat > 0 {
                return false
            }
            
            // Apply receipt filter
            if filterOptions.showMissingReceipts && expense.receiptImagePath != nil {
                return false
            }
            
            return true
        }
        
        // Group filtered expenses by month
        let groupedByMonth = Dictionary(grouping: filteredExpenses) { expense in
            formatter.string(from: expense.date)
        }
        
        return groupedByMonth.map { month, expenses in
            let groupedByDay = Dictionary(grouping: expenses) { expense in
                dayFormatter.string(from: expense.date)
            }
            
            let sortedDays = groupedByDay.map { day, dayExpenses in
                (day, dayExpenses.sorted { $0.date > $1.date }, dayExpenses.reduce(0) { $0 + $1.amount })
            }.sorted { day1, day2 in
                let date1 = dayFormatter.date(from: day1.0) ?? Date()
                let date2 = dayFormatter.date(from: day2.0) ?? Date()
                return date1 > date2
            }
            
            return (month, sortedDays)
        }.sorted { month1, month2 in
            let date1 = formatter.date(from: month1.0) ?? Date()
            let date2 = formatter.date(from: month2.0) ?? Date()
            return date1 > date2
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        // Set the locale based on selected language
        switch LanguageManager.shared.currentLanguage {
        case .turkish:
            formatter.locale = Locale(identifier: "tr")
        case .english:
            formatter.locale = Locale(identifier: "en")
        case .system:
            formatter.locale = Locale.current
        }
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                MonthSelectorView(
                    monthYearString: monthYearString,
                    onPrevious: previousMonth,
                    onNext: nextMonth
                )
                
                // Add FilterBar
                FilterBar(
                    filterOptions: $filterOptions,
                    showingMemoSearch: $showingMemoSearch,
                    expenseManager: expenseManager
                )
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack {
                        if filterOptions.isActive {
                            ClearFiltersButton(filterOptions: $filterOptions)
                                .padding(.top, 8)
                        }
                        
                        if groupedExpenses.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .padding(.top, 60)
                                
                                Text("no_expenses_found".localized)
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                
                                Text("add_your_first_expense_for".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            VStack(spacing: 20) {
                                ForEach(groupedExpenses, id: \.0) { month, days in
                                    VStack(alignment: .leading, spacing: 16) {
                                        ForEach(days, id: \.0) { day, expenses, dayTotal in
                                            DayExpensesView(
                                                day: day,
                                                expenses: expenses,
                                                dayTotal: dayTotal,
                                                expenseManager: expenseManager
                                            )
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 120)
                }
                .id(selectedDate)
            }
            
            if let currentMonth = groupedExpenses.first {
                MonthlyTotalView(
                    total: currentMonth.1.reduce(0) { $0 + $1.2 }
                )
            } else {
                MonthlyTotalView(total: 0)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDate)
        .sheet(isPresented: $showingMemoSearch) {
            MemoSearchView(
                searchText: $filterOptions.memoSearch,
                isPresented: $showingMemoSearch,
                expenseManager: expenseManager
            )
        }
    }
    
    private func previousMonth() {
        slideDirection = .right
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        slideDirection = .left
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct HomeView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var selectedTab: TabSelection
    
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        // Set the locale based on selected language
        switch LanguageManager.shared.currentLanguage {
        case .turkish:
            formatter.locale = Locale(identifier: "tr")
        case .english:
            formatter.locale = Locale(identifier: "en")
        case .system:
            formatter.locale = Locale.current
        }
        return formatter.string(from: Date())
    }
    
    private var todaysExpenses: [Expense] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return expenseManager.expenses
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { $0 }
    }
    
    private var categoryExpenses: [(category: ExpenseCategory, amount: Double)] {
        expenseManager.currentMonthExpensesByCategory()
    }
    
    private var dailyTotal: Double {
        todaysExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack {
            // Month/Year and Amount
            VStack(spacing: 8) {
                Text(currentMonthYear)
                    .foregroundColor(Color.cyan.opacity(0.8))
                    .font(.title3)
                
                Text("₺\(expenseManager.currentMonthExpenses, specifier: "%.2f")")
                    .foregroundColor(.cyan)
                    .font(.system(size: 48, weight: .medium))
                
                // VAT Display
                HStack {
                    Text("vat".localized + ":")
                        .foregroundColor(.gray)
                    Text("₺\(expenseManager.currentMonthVAT, specifier: "%.2f")")
                        .foregroundColor(.cyan.opacity(0.8))
                }
                .font(.system(size: 16))
            }
            .padding(.top, 60)
            
            // Category Distribution Bar
            if !categoryExpenses.isEmpty {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(categoryExpenses, id: \.category) { item in
                            let width = (item.amount / expenseManager.currentMonthExpenses) * geometry.size.width
                            
                            Rectangle()
                                .fill(categoryColor(for: item.category))
                                .frame(width: width)
                                .overlay(
                                    Image(systemName: item.category.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .opacity(width > 20 ? 1 : 0)
                                )
                        }
                    }
                }
                .frame(height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Legend (top 3 categories)
                HStack(spacing: 16) {
                    ForEach(categoryExpenses.prefix(3), id: \.category) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(categoryColor(for: item.category))
                                .frame(width: 8, height: 8)
                            // Update this line to use localized category name
                            Text(item.category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(Int((item.amount / expenseManager.currentMonthExpenses) * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Today's Expenses List
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedTab = .log
                        }
                    }) {
                        HStack {
                            Text("todays_expenses".localized)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .opacity(0.8)
                        }
                    }
                    
                    Spacer()
                    
                    // Add daily total here
                    Text("₺\(dailyTotal, specifier: "%.2f")")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                if todaysExpenses.isEmpty {
                    Text("no_expenses_today".localized)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(todaysExpenses) { expense in
                        ExpenseRow(expense: expense, expenseManager: expenseManager)
                    }
                }
            }
            .padding(.vertical)
            
            Spacer()
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
                Text("-₺\(expense.amount, specifier: "%.2f")")
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

// Update ExpenseDetailsView to include memo suggestions
struct ExpenseDetailsView: View {
    let category: ExpenseCategory
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    
    @State private var amount: String = ""
    @State private var memo: String = ""
    @State private var showingDatePicker = false
    @State private var selectedDateOption: DateOption = .today
    @State private var vatAmount: String = ""
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isVATFocused: Bool
    @FocusState private var isMemoFocused: Bool
    @State private var showMemoSuggestions = false
    @State private var showingCamera = false
    @State private var receiptImage: UIImage?
    @State private var showingFullScreenImage = false
    @State private var shouldDeleteImage = false
    
    private func formatNumberString(_ input: String) -> String {
        // Replace comma with period for consistency
        let sanitized = input.replacingOccurrences(of: ",", with: ".")
        
        // Only allow one decimal separator
        let components = sanitized.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        
        return sanitized
    }
    
    var memoSuggestions: [String] {
        guard !memo.isEmpty else { return [] }
        return expenseManager.previousMemos(for: category, startingWith: memo)
    }
    
    var body: some View {
        NavigationView {
            ZStack {  // Add ZStack to layer tap gesture
                Color.black.opacity(0.01)  // Nearly transparent background for tap detection
                    .onTapGesture {
                        isAmountFocused = false  // Dismiss keyboard
                        isVATFocused = false
                        isMemoFocused = false
                    }
                
                VStack(spacing: 24) {
                    // Category Chip
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                        Text(category.localizedName)  // Change this line
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
                                Text("₺")
                                    .font(.system(size: 72, weight: .regular))
                                    .foregroundColor(.white)
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
                        TextField("memo".localized, text: $memo)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .focused($isMemoFocused)
                            .onChange(of: memo) { oldValue, newValue in
                                showMemoSuggestions = !newValue.isEmpty
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
                leading: Button("cancel".localized) {
                    isPresented = false
                },
                trailing: Button("add_expense".localized) {
                    if let amountDouble = Double(amount),
                       amountDouble > 0 {
                        let vatDouble = Double(vatAmount) ?? 0
                        
                        // Save image if exists
                        var imagePath: String? = nil
                        if let image = receiptImage {
                            imagePath = ImageManager.shared.saveImage(image, forExpense: UUID())
                        }
                        
                        let expense = Expense(
                            amount: amountDouble,
                            vat: vatDouble,
                            category: category,
                            memo: memo,
                            date: selectedDateOption.date,
                            receiptImagePath: imagePath
                        )
                        expenseManager.addExpense(expense)
                        isPresented = false
                    }
                }
                .disabled(amount.isEmpty || Double(amount) == 0)
            )
            .background(Color.black.edgesIgnoringSafeArea(.all))
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
                // Activate the amount field when the view appears
                // Adding a slight delay ensures the focus works reliably
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAmountFocused = true
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        // Set locale based on selected language
        switch LanguageManager.shared.currentLanguage {
        case .turkish:
            formatter.locale = Locale(identifier: "tr")
        case .english:
            formatter.locale = Locale(identifier: "en")
        case .system:
            formatter.locale = Locale.current
        }
        return formatter.string(from: selectedDateOption.date)
    }
}

// Add this new view at the bottom of the file
struct SettingsView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showingResetAlert = false
    @State private var showingConfirmationAlert = false
    @State private var showingSuccessMessage = false
    @State private var showingExportPicker = false
    @State private var selectedExportDate = Date()
    @State private var showingImageExportPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 24) {
                    // Language settings group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("language".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Menu {
                            ForEach([LanguageManager.Language.system,
                                   .english,
                                   .turkish], id: \.self) { language in
                                Button(action: {
                                    languageManager.currentLanguage = language
                                }) {
                                    HStack {
                                        Text(language.displayName)
                                        if languageManager.currentLanguage == language {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text(languageManager.currentLanguage.displayName)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.cyan)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical)
                    
                    // Export options group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("export_description".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingExportPicker = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("export_expenses".localized)
                                Spacer()
                            }
                            .foregroundColor(.cyan)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            showingImageExportPicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("export_images".localized)
                                Spacer()
                            }
                            .foregroundColor(.cyan)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical)
                    
                    // Reset data group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("reset_warning".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("reset_all_data".localized)
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
                .navigationTitle("settings".localized)
                
                // Success message overlay
                if showingSuccessMessage {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("data_reset_success".localized)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("reset_all_data".localized, isPresented: $showingResetAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("reset".localized, role: .destructive) {
                showingConfirmationAlert = true
            }
        } message: {
            Text("reset_warning".localized)
        }
        .alert("reset_confirm".localized, isPresented: $showingConfirmationAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("yes_reset".localized, role: .destructive) {
                expenseManager.resetAllData()
                withAnimation {
                    showingSuccessMessage = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showingSuccessMessage = false
                    }
                }
            }
        } message: {
            Text("reset_confirm".localized)
        }
        .sheet(isPresented: $showingExportPicker) {
            NavigationView {
                ExportPickerView(
                    date: $selectedExportDate,
                    expenseManager: expenseManager,
                    isPresented: $showingExportPicker
                )
            }
        }
        .sheet(isPresented: $showingImageExportPicker) {
            NavigationView {
                ExportImagesView(
                    date: $selectedExportDate,
                    expenseManager: expenseManager,
                    isPresented: $showingImageExportPicker
                )
            }
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
                isShowingAmount ? Text("₺\(amount, specifier: "%.0f")")
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
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 0
    }
    
    private var firstDayWeekday: Int {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDay = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: firstDay) - 1 // 0 is Sunday
    }
    
    private var dailyExpenses: [(date: Date, amount: Double)] {
        var result: [(Date, Double)] = []
        
        // Create date components for the start of the month
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        
        // Get daily totals
        for day in 1...daysInMonth {
            components.day = day
            guard let date = calendar.date(from: components) else { continue }
            
            let dayExpenses = expenses.filter { expense in
                calendar.isDate(expense.date, inSameDayAs: date)
            }
            
            let total = dayExpenses.reduce(0) { $0 + $1.amount }
            result.append((date, total))
        }
        
        return result
    }
    
    private var maxDailyAmount: Double {
        dailyExpenses.map { $0.amount }.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("spending_heatmap".localized)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // Empty cells for first week alignment
                ForEach(0..<firstDayWeekday, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 30)
                }
                
                // Day cells
                ForEach(dailyExpenses, id: \.date) { day in
                    DayHeatmapCell(
                        date: day.date,
                        amount: day.amount,
                        maxAmount: maxDailyAmount
                    )
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                Text(title)
                    .foregroundColor(.gray)
            }
            .font(.system(size: 14))
            
            Text("₺\(amount, specifier: "%.2f")")
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
                            Text("₺\(data.amount, specifier: "%.0f")")
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

// Update InsightsView to include the statistics
struct InsightsView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @State private var selectedDate = Date()
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        switch LanguageManager.shared.currentLanguage {
            case .turkish:
                formatter.locale = Locale(identifier: "tr")
            case .english:
                formatter.locale = Locale(identifier: "en")
            case .system:
                formatter.locale = Locale.current
            }
        return formatter.string(from: selectedDate)
    }
    
    private var expensesForSelectedMonth: [(category: ExpenseCategory, amount: Double)] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedDate)
        let year = calendar.component(.year, from: selectedDate)
        
        let filteredExpenses = expenseManager.expenses.filter { expense in
            let components = calendar.dateComponents([.month, .year], from: expense.date)
            return components.month == month && components.year == year
        }
        
        var categoryTotals: [ExpenseCategory: Double] = [:]
        
        for expense in filteredExpenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals.map { ($0.key, $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    private var totalForSelectedMonth: Double {
        expensesForSelectedMonth.reduce(0) { $0 + $1.amount }
    }
    
    private var previousMonthTotal: Double {
        let calendar = Calendar.current
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedDate) else { return 0 }
        
        let month = calendar.component(.month, from: previousMonth)
        let year = calendar.component(.year, from: previousMonth)
        
        let filteredExpenses = expenseManager.expenses.filter { expense in
            let components = calendar.dateComponents([.month, .year], from: expense.date)
            return components.month == month && components.year == year
        }
        
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Add the categoryColor function
    private func categoryColor(_ category: ExpenseCategory) -> Color {
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
    
    private var safeAreaTop: CGFloat {
        UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 47
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Month selector with safe area spacing
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: safeAreaTop)
                    
                    MonthSelectorView(
                        monthYearString: monthYearString,
                        onPrevious: { withAnimation { selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate } },
                        onNext: { withAnimation { selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate } }
                    )
                }
                .background(Color(red: 0.05, green: 0.05, blue: 0.2))
                
                // Add comparison indicator
                if !expensesForSelectedMonth.isEmpty {
                    MonthComparisonView(
                        currentAmount: totalForSelectedMonth,
                        previousAmount: previousMonthTotal
                    )
                    .padding(.top, 8)
                }
                
                // Pie Chart
                if !expensesForSelectedMonth.isEmpty {
                    GeometryReader { geometry in
                        PieChartView(
                            categories: expensesForSelectedMonth,
                            size: min(geometry.size.width, geometry.size.height) * 0.8,
                            categoryColor: categoryColor
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: 250)
                    .padding(.horizontal)
                    .padding(.top, -8)
                    
                    // Category Legend
                    CategoryLegendView(
                        categories: expensesForSelectedMonth,
                        total: totalForSelectedMonth,
                        categoryColor: categoryColor
                    )
                } else {
                    EmptyStateView(monthYearString: monthYearString)
                }
                
                if !expensesForSelectedMonth.isEmpty {
                    // Add monthly statistics before the heatmap
                    MonthlyStatisticsView(
                        expenses: expenseManager.expenses.filter { expense in
                            let components = Calendar.current.dateComponents([.month, .year], from: expense.date)
                            let selectedComponents = Calendar.current.dateComponents([.month, .year], from: selectedDate)
                            return components.month == selectedComponents.month && 
                                   components.year == selectedComponents.year
                        },
                        currentDate: selectedDate
                    )
                    
                    // Add weekly expense chart
                    WeeklyExpenseChartView(
                        expenses: expenseManager.expenses.filter { expense in
                            let components = Calendar.current.dateComponents([.month, .year], from: expense.date)
                            let selectedComponents = Calendar.current.dateComponents([.month, .year], from: selectedDate)
                            return components.month == selectedComponents.month && 
                                   components.year == selectedComponents.year
                        },
                        currentDate: selectedDate
                    )
                    
                    // Existing heatmap
                    ExpenseHeatmapView(
                        expenses: expenseManager.expenses.filter { expense in
                            let components = Calendar.current.dateComponents([.month, .year], from: expense.date)
                            let selectedComponents = Calendar.current.dateComponents([.month, .year], from: selectedDate)
                            return components.month == selectedComponents.month && 
                                   components.year == selectedComponents.year
                        },
                        currentDate: selectedDate
                    )
                }
            }
            .padding(.bottom, 50)
        }
        .ignoresSafeArea(edges: .top)
    }
}

// Create a separate view for the empty state
struct EmptyStateView: View {
    let monthYearString: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.top, 40)
            
            Text("\("no_expenses_in".localized) \(monthYearString)")
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("add_first_expense".localized)
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// Helper struct to store slice information
struct PieSliceData {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let category: ExpenseCategory
    let amount: Double
}

// Update PieSlice to be a donut slice
struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    // Add innerRadius ratio (0.6 means the inner circle will be 60% of the outer radius)
    private let innerRadiusRatio: CGFloat = 0.6
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * innerRadiusRatio
        
        // Outer arc
        path.addArc(center: center,
                   radius: radius,
                   startAngle: startAngle,
                   endAngle: endAngle,
                   clockwise: false)
        
        // Line to inner arc
        path.addLine(to: CGPoint(
            x: center.x + innerRadius * CGFloat(cos(endAngle.radians)),
            y: center.y + innerRadius * CGFloat(sin(endAngle.radians))))
        
        // Inner arc
        path.addArc(center: center,
                   radius: innerRadius,
                   startAngle: endAngle,
                   endAngle: startAngle,
                   clockwise: true)
        
        // Close path
        path.closeSubpath()
        
        return path
    }
}

// Update PieChartView to include selection
struct PieChartView: View {
    let categories: [(category: ExpenseCategory, amount: Double)]
    let size: CGFloat
    let categoryColor: (ExpenseCategory) -> Color
    
    @State private var selectedCategory: ExpenseCategory?
    
    private var total: Double {
        categories.reduce(0) { $0 + $1.amount }
    }
    
    private var slices: [PieSliceData] {
        var startAngle = Angle.degrees(-90)
        
        return categories.map { category in
            let angle = Angle.degrees(360 * (category.amount / total))
            let slice = PieSliceData(
                startAngle: startAngle,
                endAngle: startAngle + angle,
                color: categoryColor(category.category),
                category: category.category,
                amount: category.amount
            )
            startAngle += angle
            return slice
        }
    }
    
    // Get the display content (selected category or total)
    private var displayContent: (title: String, amount: Double) {
        if let selected = selectedCategory,
           let category = categories.first(where: { $0.category == selected }) {
            return (category.category.rawValue, category.amount)
        }
        return ("total".localized, total)
    }
    
    var body: some View {
        ZStack {
            // Donut slices
            ForEach(Array(slices.enumerated()), id: \.offset) { _, slice in
                PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle)
                    .fill(slice.color)
                    .opacity(selectedCategory == nil || selectedCategory == slice.category ? 1.0 : 0.3)
                    .overlay(
                        PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle)
                            .stroke(Color.white.opacity(selectedCategory == slice.category ? 0.5 : 0), lineWidth: 2)
                    )
                    .scaleEffect(selectedCategory == slice.category ? 1.05 : 1.0)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = selectedCategory == slice.category ? nil : slice.category
                        }
                    }
            }
            
            // Center content
            VStack(spacing: 4) {
                Text(displayContent.title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text("-₺\(displayContent.amount, specifier: "%.2f")")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .frame(width: size * 0.5)
            .multilineTextAlignment(.center)
            .transition(.opacity)
            .id(displayContent.title) // Force view update when content changes
        }
        .frame(width: size, height: size)
    }
}

// Add new ExpenseDetailsEditView
struct ExpenseDetailsEditView: View {
    let expense: Expense
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    
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
                                Text("₺")
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
                        TextField("memo".localized, text: $memo)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .focused($isMemoFocused)
                            .onChange(of: memo) { oldValue, newValue in
                                showMemoSuggestions = !newValue.isEmpty
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
                leading: Button("cancel".localized) {
                    isPresented = false
                },
                trailing: HStack(spacing: 16) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                    }
                }
            )
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
            .onChange(of: shouldDeleteImage) { oldValue, newValue in
                if newValue {
                    receiptImage = nil
                    if let oldPath = expense.receiptImagePath {
                        ImageManager.shared.deleteImage(filename: oldPath)
                    }
                    shouldDeleteImage = false
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

struct ExportImagesView: View {
    @Binding var date: Date
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    @State private var isExporting = false
    
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
            
            if isExporting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Export Receipt Images")
        .navigationBarItems(
            leading: Button("Cancel") {
                isPresented = false
            },
            trailing: Button("Export") {
                exportImages()
            }
        )
    }
    
    private func exportImages() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let zipURL = createZipFile() {
                DispatchQueue.main.async {
                    isExporting = false
                    presentShareSheet(url: zipURL)
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    // TODO: Show error alert
                }
            }
        }
    }
    
    private func createZipFile() -> URL? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        // Filter expenses for selected month
        let monthExpenses = expenseManager.expenses.filter { expense in
            let components = calendar.dateComponents([.month, .year], from: expense.date)
            return components.month == month && components.year == year
        }
        
        // Create temporary directory for images
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM_yyyy"
        let dirName = "Expense_Images_\(formatter.string(from: date))"
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(dirName)
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(dirName).zip")
        
        do {
            // Create temp directory
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Copy and rename images
            for expense in monthExpenses {
                if let imagePath = expense.receiptImagePath {
                    let sourcePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(imagePath)
                    
                    // Create formatted date string
                    formatter.dateFormat = "yyyy-MM-dd_HH-mm"
                    let dateStr = formatter.string(from: expense.date)
                    
                    // Create new filename
                    let newFileName = "\(expense.category.rawValue)_\(dateStr)_receipt.jpg"
                    let destinationURL = tempDir.appendingPathComponent(newFileName)
                    
                    // Copy the already-compressed image
                    try FileManager.default.copyItem(at: sourcePath, to: destinationURL)
                }
            }
            
            // Create zip file
            try ZipManager.createZip(at: tempDir, to: zipURL)
            
            // Clean up temp directory
            try FileManager.default.removeItem(at: tempDir)
            
            return zipURL
        } catch {
            print("Error creating zip file: \(error)")
            return nil
        }
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
}

// Update FilterBar to use a dropdown for categories
struct FilterBar: View {
    @Binding var filterOptions: FilterOptions
    @Binding var showingMemoSearch: Bool
    @ObservedObject var expenseManager: ExpenseManager // Add this
    @State private var showingCategoryPicker = false
    
    private var selectedCategoriesText: String {
        if filterOptions.selectedCategories.isEmpty {
            return "category".localized
        } else if filterOptions.selectedCategories.count == 1 {
            return filterOptions.selectedCategories.first?.rawValue ?? ""
        } else {
            return "\(filterOptions.selectedCategories.count) Categories"
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Memo search button
                FilterChip(
                    icon: "magnifyingglass",
                    label: filterOptions.memoSearch.isEmpty ? "search_memo".localized : filterOptions.memoSearch,
                    isSelected: !filterOptions.memoSearch.isEmpty,
                    action: { showingMemoSearch = true }
                )
                
                // Category dropdown
                Menu {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button(action: {
                            if filterOptions.selectedCategories.contains(category) {
                                filterOptions.selectedCategories.remove(category)
                            } else {
                                filterOptions.selectedCategories.insert(category)
                            }
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                                if filterOptions.selectedCategories.contains(category) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    if !filterOptions.selectedCategories.isEmpty {
                        Divider()
                        Button(role: .destructive, action: {
                            filterOptions.selectedCategories.removeAll()
                        }) {
                            Text("Clear Categories")
                        }
                    }
                } label: {
                    FilterChip(
                        icon: "folder",
                        label: selectedCategoriesText,
                        isSelected: !filterOptions.selectedCategories.isEmpty,
                        showsMenuIndicator: true
                    )
                }
                
                
                // Missing VAT filter
                FilterChip(
                    icon: "percent",
                    label: "missing_vat".localized,
                    isSelected: filterOptions.showMissingVAT,
                    action: { filterOptions.showMissingVAT.toggle() }
                )
                
                // Missing receipt filter
                FilterChip(
                    icon: "doc.text",
                    label: "no_receipt".localized,
                    isSelected: filterOptions.showMissingReceipts,
                    action: { filterOptions.showMissingReceipts.toggle() }
                )
            }
            .padding(.horizontal)
        }
    }
}

// Update FilterChip to support menu indicator
struct FilterChip: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var action: (() -> Void)? = nil
    var showsMenuIndicator: Bool = false
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    chipContent
                }
            } else {
                chipContent
            }
        }
    }
    
    private var chipContent: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(label)
                .font(.system(size: 14))
            if showsMenuIndicator {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
        .foregroundColor(isSelected ? .white : .gray)
        .cornerRadius(20)
    }
}

struct ClearFiltersButton: View {
    @Binding var filterOptions: FilterOptions
    
    var body: some View {
        Button(action: { filterOptions.clear() }) {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                Text("clear_filters".localized)
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
        }
    }
}

struct EmptyFilterView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.top, 60)
            
            Text("no_matching_expenses".localized)
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("try_adjusting_your_filters".localized)
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct MemoSearchView: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    @ObservedObject var expenseManager: ExpenseManager // Add this
    @FocusState private var isFocused: Bool
    
    private var filteredMemos: [String] {
        // Get unique memos from all expenses
        let allMemos = Set(expenseManager.expenses.map { $0.memo })
        
        // Filter memos that contain the search text
        return Array(allMemos)
            .filter { !$0.isEmpty && $0.localizedCaseInsensitiveContains(searchText) }
            .sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("Search memos...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focused($isFocused)
                
                if !searchText.isEmpty {
                    List(filteredMemos, id: \.self) { memo in
                        Button(action: {
                            searchText = memo
                            isPresented = false
                        }) {
                            HStack {
                                Text(memo)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    // Show recently used memos when search is empty
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Memos")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(recentMemos, id: \.self) { memo in
                                    Button(action: {
                                        searchText = memo
                                        isPresented = false
                                    }) {
                                        HStack {
                                            Text(memo)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "clock.arrow.circlepath")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14))
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Memos")
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
        .onAppear {
            isFocused = true
        }
    }
    
    // Get recent unique memos, limited to last 10
    private var recentMemos: [String] {
        Array(Set(expenseManager.expenses
            .sorted { $0.date > $1.date }
            .prefix(50)
            .map { $0.memo }
            .filter { !$0.isEmpty }
        )).prefix(10).sorted()
    }
}

#Preview {
    ContentView()
}
