import Foundation

struct FilterOptions {
    var selectedCategories: Set<ExpenseCategory> = []
    var memoSearch: String = ""
    var showMissingVAT: Bool = false
    var showMissingReceipts: Bool = false
    
    var isActive: Bool {
        !selectedCategories.isEmpty || 
        !memoSearch.isEmpty || 
        showMissingVAT || 
        showMissingReceipts
    }
    
    mutating func clear() {
        selectedCategories.removeAll()
        memoSearch = ""
        showMissingVAT = false
        showMissingReceipts = false
    }
} 