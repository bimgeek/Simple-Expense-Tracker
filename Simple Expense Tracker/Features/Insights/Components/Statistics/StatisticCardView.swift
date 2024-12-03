import SwiftUI

struct StatisticCardView: View {
    let title: String
    let amount: Double
    let icon: String
    @StateObject private var currencyManager = CurrencyManager.shared

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                Text(title)
                    .foregroundColor(.gray)
            }
            .font(.system(size: 14))
            
            Text("\(currencyManager.currentCurrency.symbol)\(amount, specifier: "%.2f")")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}