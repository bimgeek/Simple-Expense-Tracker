import SwiftUI

struct TabBarItem: View {
    let icon: String
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(text)
                .font(.caption)
        }
        .foregroundColor(isSelected ? .cyan : .gray)
    }
}