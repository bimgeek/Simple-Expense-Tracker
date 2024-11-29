import SwiftUI

struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @Binding var shouldDeleteImage: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @GestureState private var magnifyBy = CGFloat(1.0)
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                        .scaleEffect(scale * magnifyBy)
                        .gesture(
                            MagnificationGesture()
                                .updating($magnifyBy) { currentState, gestureState, transaction in
                                    gestureState = currentState
                                }
                                .onEnded { value in
                                    scale *= value
                                    scale = min(max(scale, 1), 4)
                                }
                        )
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title2)
                },
                trailing: Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title)
                }
            )
            .alert("Delete Receipt", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    shouldDeleteImage = true
                    isPresented = false
                }
            } message: {
                Text("Are you sure you want to delete this receipt image?")
            }
            .background(Color.black)
        }
    }
} 