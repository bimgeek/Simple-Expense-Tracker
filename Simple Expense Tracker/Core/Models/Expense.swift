import Foundation

struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let vat: Double
    let category: ExpenseCategory
    let memo: String
    let date: Date
    let receiptImagePath: String?
    
    init(id: UUID = UUID(), amount: Double, vat: Double, category: ExpenseCategory, memo: String, date: Date, receiptImagePath: String?) {
        self.id = id
        self.amount = amount
        self.vat = vat
        self.category = category
        self.memo = memo
        self.date = date
        self.receiptImagePath = receiptImagePath
    }
}