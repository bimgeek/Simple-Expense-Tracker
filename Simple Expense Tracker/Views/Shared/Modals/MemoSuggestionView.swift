import SwiftUI

struct MemoSuggestionView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { memo in
                    Button(action: { onSelect(memo) }) {
                        Text(memo)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: suggestions.isEmpty ? 0 : 44)
    }
}