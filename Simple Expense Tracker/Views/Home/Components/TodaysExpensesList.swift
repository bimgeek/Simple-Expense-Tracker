import SwiftUI

struct TodaysExpensesList: View {
    let todaysExpenses: [Expense]
    let dailyTotal: Double
    @Binding var selectedTab: TabSelection
    @ObservedObject var expenseManager: ExpenseManager
    @StateObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
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
                
                Text("\(currencyManager.currentCurrency.symbol)\(dailyTotal, specifier: "%.2f")")
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
    }
} 