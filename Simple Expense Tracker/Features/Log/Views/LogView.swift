import SwiftUI

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