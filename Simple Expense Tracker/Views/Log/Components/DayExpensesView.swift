import SwiftUI

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