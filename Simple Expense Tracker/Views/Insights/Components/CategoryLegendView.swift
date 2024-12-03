import SwiftUI

struct CategoryLegendView: View {
    let categories: [(category: ExpenseCategory, amount: Double)]
    let total: Double
    let categoryColor: (ExpenseCategory) -> Color
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(categories, id: \.category) { item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(categoryColor(item.category))
                        .frame(width: 12, height: 12)
                    
                    Text(item.category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(item.amount, specifier: "%.2f")")
                        .foregroundColor(.gray)
                    
                    Text("(\(Int((item.amount / total) * 100))%")
                        .foregroundColor(.gray)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, -8)
    }
}