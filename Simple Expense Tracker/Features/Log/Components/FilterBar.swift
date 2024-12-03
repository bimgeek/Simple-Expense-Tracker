import SwiftUI

struct FilterBar: View {
    @Binding var filterOptions: FilterOptions
    @Binding var showingMemoSearch: Bool
    @ObservedObject var expenseManager: ExpenseManager // Add this
    @State private var showingCategoryPicker = false
    
    private var selectedCategoriesText: String {
        if filterOptions.selectedCategories.isEmpty {
            return "category".localized
        } else if filterOptions.selectedCategories.count == 1 {
            return filterOptions.selectedCategories.first?.rawValue ?? ""
        } else {
            return "\(filterOptions.selectedCategories.count) Categories"
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Memo search button
                FilterChip(
                    icon: "magnifyingglass",
                    label: filterOptions.memoSearch.isEmpty ? "search_memo".localized : filterOptions.memoSearch,
                    isSelected: !filterOptions.memoSearch.isEmpty,
                    action: { showingMemoSearch = true }
                )
                
                // Category dropdown
                Menu {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button(action: {
                            if filterOptions.selectedCategories.contains(category) {
                                filterOptions.selectedCategories.remove(category)
                            } else {
                                filterOptions.selectedCategories.insert(category)
                            }
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                                if filterOptions.selectedCategories.contains(category) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    if !filterOptions.selectedCategories.isEmpty {
                        Divider()
                        Button(role: .destructive, action: {
                            filterOptions.selectedCategories.removeAll()
                        }) {
                            Text("Clear Categories")
                        }
                    }
                } label: {
                    FilterChip(
                        icon: "folder",
                        label: selectedCategoriesText,
                        isSelected: !filterOptions.selectedCategories.isEmpty,
                        showsMenuIndicator: true
                    )
                }
                
                
                // Missing VAT filter
                FilterChip(
                    icon: "percent",
                    label: "missing_vat".localized,
                    isSelected: filterOptions.showMissingVAT,
                    action: { filterOptions.showMissingVAT.toggle() }
                )
                
                // Missing receipt filter
                FilterChip(
                    icon: "doc.text",
                    label: "no_receipt".localized,
                    isSelected: filterOptions.showMissingReceipts,
                    action: { filterOptions.showMissingReceipts.toggle() }
                )
            }
            .padding(.horizontal)
        }
    }
}