import SwiftUI

struct EmptyFilterView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.top, 60)
            
            Text("no_matching_expenses".localized)
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("try_adjusting_your_filters".localized)
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}