import SwiftUI

struct CategoryBar: View {
    let categoryExpenses: [(category: ExpenseCategory, amount: Double)]
    let monthlyTotal: Double
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(categoryExpenses, id: \.category) { item in
                        let width = (item.amount / monthlyTotal) * geometry.size.width
                        
                        Rectangle()
                            .fill(categoryColor(for: item.category))
                            .frame(width: width)
                            .overlay(
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .opacity(width > 20 ? 1 : 0)
                            )
                    }
                }
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            // Legend (top 3 categories)
            HStack(spacing: 16) {
                ForEach(categoryExpenses.prefix(3), id: \.category) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(categoryColor(for: item.category))
                            .frame(width: 8, height: 8)
                        Text(item.category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(Int((item.amount / monthlyTotal) * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
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