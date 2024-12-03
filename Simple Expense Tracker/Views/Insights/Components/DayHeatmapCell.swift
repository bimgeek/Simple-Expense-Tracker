import SwiftUI

struct DayHeatmapCell: View {
    let date: Date
    let amount: Double
    let maxAmount: Double
    @State private var isShowingAmount = false
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line

    
    private var opacity: Double {
        guard amount > 0 else { return 0.1 }
        return 0.2 + min(0.8, (amount / maxAmount) * 0.8)
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.red.opacity(opacity))
            .frame(height: 30)
            .cornerRadius(6)
            .overlay(
                isShowingAmount ? Text("\(currencyManager.currentCurrency.symbol)\(amount, specifier: "%.0f")")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    : nil
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingAmount.toggle()
                }
            }
    }
}