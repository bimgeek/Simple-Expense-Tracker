import SwiftUI

struct PieChartView: View {
    let categories: [(category: ExpenseCategory, amount: Double)]
    let size: CGFloat
    let categoryColor: (ExpenseCategory) -> Color
    
    @State private var selectedCategory: ExpenseCategory?
    @StateObject private var currencyManager = CurrencyManager.shared

    
    private var total: Double {
        categories.reduce(0) { $0 + $1.amount }
    }
    
    private var slices: [PieSliceData] {
        var startAngle = Angle.degrees(-90)
        
        return categories.map { category in
            let angle = Angle.degrees(360 * (category.amount / total))
            let slice = PieSliceData(
                startAngle: startAngle,
                endAngle: startAngle + angle,
                color: categoryColor(category.category),
                category: category.category,
                amount: category.amount
            )
            startAngle += angle
            return slice
        }
    }
    
    // Get the display content (selected category or total)
    private var displayContent: (title: String, amount: Double) {
        if let selected = selectedCategory,
           let category = categories.first(where: { $0.category == selected }) {
            // Update this line to use localizedName
            return (category.category.localizedName, category.amount)
        }
        return ("total".localized, total)
    }
    
    var body: some View {
        ZStack {
            // Donut slices
            ForEach(Array(slices.enumerated()), id: \.offset) { _, slice in
                PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle)
                    .fill(slice.color)
                    .opacity(selectedCategory == nil || selectedCategory == slice.category ? 1.0 : 0.3)
                    .overlay(
                        PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle)
                            .stroke(Color.white.opacity(selectedCategory == slice.category ? 0.5 : 0), lineWidth: 2)
                    )
                    .scaleEffect(selectedCategory == slice.category ? 1.05 : 1.0)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = selectedCategory == slice.category ? nil : slice.category
                        }
                    }
            }
            
            // Center content
            VStack(spacing: 4) {
                Text(displayContent.title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text("-\(currencyManager.currentCurrency.symbol)\(displayContent.amount, specifier: "%.2f")")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .frame(width: size * 0.5)
            .multilineTextAlignment(.center)
            .transition(.opacity)
            .id(displayContent.title) // Force view update when content changes
        }
        .frame(width: size, height: size)
    }
}