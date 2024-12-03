import SwiftUI

struct MonthSelectorView: View {
    let monthYearString: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    @StateObject private var currencyManager = CurrencyManager.shared

    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.cyan)
                    .font(.title3)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .foregroundColor(.cyan)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.cyan)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
}