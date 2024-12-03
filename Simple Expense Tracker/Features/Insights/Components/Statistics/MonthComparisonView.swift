import SwiftUI

struct MonthComparisonView: View {
    let currentAmount: Double
    let previousAmount: Double
    
    private var percentageChange: Double {
        guard previousAmount > 0 else { return 0 }
        return ((currentAmount - previousAmount) / previousAmount) * 100
    }
    
    private var isIncrease: Bool {
        currentAmount > previousAmount
    }
    
    var body: some View {
        if previousAmount > 0 {
            HStack(spacing: 4) {
                Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(isIncrease ? .red : .green)
                
                Text("\(abs(percentageChange), specifier: "%.1f")%")
                    .foregroundColor(isIncrease ? .red : .green)
                    .font(.system(size: 14, weight: .medium))
                
                Text("vs last month")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
}