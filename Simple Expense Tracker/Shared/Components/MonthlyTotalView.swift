import SwiftUI

struct MonthlyTotalView: View {
    let total: Double
    
    @StateObject private var currencyManager = CurrencyManager.shared

    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                Text("monthly_total".localized)
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(currencyManager.currentCurrency.symbol)\(total, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color(red: 0.05, green: 0.05, blue: 0.2).opacity(0.95))
        }
        .padding(.bottom, 49)
    }
}