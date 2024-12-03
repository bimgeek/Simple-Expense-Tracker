import SwiftUI

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