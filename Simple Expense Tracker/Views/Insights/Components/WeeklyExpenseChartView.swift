import SwiftUI

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