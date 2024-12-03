import SwiftUI

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