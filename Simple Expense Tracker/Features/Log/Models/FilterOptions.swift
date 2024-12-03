import Foundation

struct FilterOptions {
    var selectedCategories: Set<ExpenseCategory> = []
    var memoSearch: String = ""
    var showMissingVAT: Bool = false
    var showMissingReceipts: Bool = false
    var sortOption: SortOption = .date
    var groupByDay: Bool = true
    
    var isActive: Bool {
        !selectedCategories.isEmpty || 
        !memoSearch.isEmpty || 
        showMissingVAT || 
        showMissingReceipts ||
        sortOption != .date ||
        !groupByDay
    }
    
    mutating func clear() {
        selectedCategories.removeAll()
        memoSearch = ""
        showMissingVAT = false
        showMissingReceipts = false
        sortOption = .date
        groupByDay = true
    }
} 