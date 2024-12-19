import SwiftUI

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
                        .frame(height: 20)
                    
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

// First, add this helper view for the tooltip
struct AmountTooltip: View {
    let amount: Double
    @StateObject private var currencyManager = CurrencyManager.shared

    
    var body: some View {
        Text("\(currencyManager.currentCurrency.symbol)\(amount, specifier: "%.2f")")
            .font(.system(size: 12))
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minWidth: 80) // Set a minimum width for the tooltip
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.8))
            )
    }
}

// Then update the cell implementation in ExpenseHeatmapView
struct HeatmapCell: View {
    let day: Int
    let amount: Double
    let maxAmount: Double
    @State private var isShowingTooltip = false
    
    private var normalizedAmount: Double {
        maxAmount > 0 ? amount / maxAmount : 0
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.red.opacity(normalizedAmount * 0.8 + 0.1))
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(4)
            
            Text("\(day)")
                .font(.system(size: 10))
                .foregroundColor(.white)
                .opacity(0.5)
            
            if isShowingTooltip && amount > 0 {
                AmountTooltip(amount: amount)
                    .offset(y: -25)
                    .transition(.opacity)
                    .zIndex(1)
                    .fixedSize(horizontal: true, vertical: false) // Allow horizontal expansion
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingTooltip.toggle()
            }
        }
    }
}