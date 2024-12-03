import SwiftUI

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