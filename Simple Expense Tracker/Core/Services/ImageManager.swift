import UIKit

class ImageManager {
    static let shared = ImageManager()
    
    private init() {}
    
    func saveImage(_ image: UIImage, forExpense expenseId: UUID) -> String? {
        // Resize image if it's too large
        let maxDimension: CGFloat = 1500
        let resizedImage: UIImage
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }
        
        // Compress image
        guard let data = resizedImage.jpegData(compressionQuality: 0.5) else { return nil }
        
        let filename = "\(expenseId.uuidString).jpg"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        
        do {
            try data.write(to: path)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImage(filename: String) -> UIImage? {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }
    
    func deleteImage(filename: String) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: path)
    }
} 