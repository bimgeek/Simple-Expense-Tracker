import SwiftUI

struct MemoSearchView: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    @ObservedObject var expenseManager: ExpenseManager // Add this
    @FocusState private var isFocused: Bool
    @StateObject private var currencyManager = CurrencyManager.shared

    
    private var filteredMemos: [String] {
        // Get unique memos from all expenses
        let allMemos = Set(expenseManager.expenses.map { $0.memo })
        
        // Filter memos that contain the search text
        return Array(allMemos)
            .filter { !$0.isEmpty && $0.localizedCaseInsensitiveContains(searchText) }
            .sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("Search memos...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focused($isFocused)
                
                if !searchText.isEmpty {
                    List(filteredMemos, id: \.self) { memo in
                        Button(action: {
                            searchText = memo
                            isPresented = false
                        }) {
                            HStack {
                                Text(memo)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    // Show recently used memos when search is empty
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Memos")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(recentMemos, id: \.self) { memo in
                                    Button(action: {
                                        searchText = memo
                                        isPresented = false
                                    }) {
                                        HStack {
                                            Text(memo)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "clock.arrow.circlepath")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14))
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Memos")
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
        .onAppear {
            isFocused = true
        }
    }
    
    // Get recent unique memos, limited to last 10
    private var recentMemos: [String] {
        Array(Set(expenseManager.expenses
            .sorted { $0.date > $1.date }
            .prefix(50)
            .map { $0.memo }
            .filter { !$0.isEmpty }
        )).prefix(10).sorted()
    }
}