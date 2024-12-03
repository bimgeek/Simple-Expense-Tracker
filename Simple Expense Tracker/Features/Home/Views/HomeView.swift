import SwiftUI

struct HomeView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var selectedTab: TabSelection
    @StateObject private var currencyManager = CurrencyManager.shared
    
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
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
                
                Text("\(currencyManager.currentCurrency.symbol)\(expenseManager.currentMonthExpenses, specifier: "%.2f")")
                    .foregroundColor(.cyan)
                    .font(.system(size: 48, weight: .medium))
                
                // VAT Display
                HStack {
                    Text("vat".localized + ":")
                        .foregroundColor(.gray)
                    Text("\(currencyManager.currentCurrency.symbol)\(expenseManager.currentMonthVAT, specifier: "%.2f")")
                        .foregroundColor(.cyan.opacity(0.8))
                }
                .font(.system(size: 16))
            }
            .padding(.top, 60)
            
            if !categoryExpenses.isEmpty {
                CategoryBar(categoryExpenses: categoryExpenses, monthlyTotal: expenseManager.currentMonthExpenses)
            }
            
            TodaysExpensesList(
                todaysExpenses: todaysExpenses,
                dailyTotal: dailyTotal,
                selectedTab: $selectedTab,
                expenseManager: expenseManager
            )
            
            Spacer()
        }
    }
} 