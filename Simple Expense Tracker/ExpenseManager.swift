import Foundation

class ExpenseManager: ObservableObject {
    @Published var expenses: [Expense] = []
    private let saveKey = "SavedExpenses"
    
    init() {
        loadExpenses()
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        saveExpenses()
    }
    
    var currentMonthExpenses: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return expenses
            .filter { expense in
                let components = Calendar.current.dateComponents([.month, .year], from: expense.date)
                return components.month == currentMonth && components.year == currentYear
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var currentMonthVAT: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return expenses
            .filter { expense in
                let components = Calendar.current.dateComponents([.month, .year], from: expense.date)
                return components.month == currentMonth && components.year == currentYear
            }
            .reduce(0) { $0 + $1.vat }
    }
    
    func currentMonthExpensesByCategory() -> [(category: ExpenseCategory, amount: Double)] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let filteredExpenses = expenses.filter { expense in
            let components = Calendar.current.dateComponents([.month, .year], from: expense.date)
            return components.month == currentMonth && components.year == currentYear
        }
        
        var categoryTotals: [ExpenseCategory: Double] = [:]
        
        for expense in filteredExpenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals.map { ($0.key, $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    private func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
    }
    
    func updateExpense(_ expense: Expense, newAmount: Double, newVat: Double, newMemo: String, newDate: Date, receiptImagePath: String?) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = Expense(
                id: expense.id,
                amount: newAmount,
                vat: newVat,
                category: expense.category,
                memo: newMemo,
                date: newDate,
                receiptImagePath: receiptImagePath
            )
            saveExpenses()
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        if let imagePath = expense.receiptImagePath {
            ImageManager.shared.deleteImage(filename: imagePath)
        }
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
    }
    
    func resetAllData() {
        expenses = []
        saveExpenses()
    }
    
    func previousMemos(for category: ExpenseCategory, startingWith prefix: String = "") -> [String] {
        // Get unique memos for the category, excluding empty ones
        let memos = Set(expenses
            .filter { $0.category == category && !$0.memo.isEmpty }
            .map { $0.memo })
        
        // Filter by prefix if provided and sort alphabetically
        return Array(memos)
            .filter { prefix.isEmpty || $0.lowercased().hasPrefix(prefix.lowercased()) }
            .sorted()
    }
} 