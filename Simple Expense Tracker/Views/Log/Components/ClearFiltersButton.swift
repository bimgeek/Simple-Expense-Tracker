import SwiftUI

struct ClearFiltersButton: View {
    @Binding var filterOptions: FilterOptions
    
    var body: some View {
        Button(action: { filterOptions.clear() }) {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                Text("clear_filters".localized)
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
        }
    }
}