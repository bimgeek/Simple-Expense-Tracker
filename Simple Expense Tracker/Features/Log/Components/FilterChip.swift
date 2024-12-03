import SwiftUI

struct FilterChip: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var action: (() -> Void)? = nil
    var showsMenuIndicator: Bool = false
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    chipContent
                }
            } else {
                chipContent
            }
        }
    }
    
    private var chipContent: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(label)
                .font(.system(size: 14))
            if showsMenuIndicator {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
        .foregroundColor(isSelected ? .white : .gray)
        .cornerRadius(20)
    }
}