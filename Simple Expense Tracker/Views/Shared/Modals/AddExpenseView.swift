import SwiftUI

struct AddExpenseView: View {
    @Binding var isPresented: Bool
    @ObservedObject var expenseManager: ExpenseManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                    ForEach(ExpenseCategory.allCases.reversed(), id: \.self) { category in
                        NavigationLink(destination: ExpenseDetailsView(
                            category: category,
                            expenseManager: expenseManager,
                            isPresented: $isPresented
                        )) {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(categoryColor(for: category))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: category.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }
                                
                                Text(category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("add_expense".localized)
            .navigationBarItems(
                leading: Button("cancel".localized) {
                    isPresented = false
                }
            )
            .background(Color.black.edgesIgnoringSafeArea(.all))
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