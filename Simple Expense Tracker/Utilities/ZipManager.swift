import Foundation

class ZipManager {
    static func createZip(at sourceURL: URL, to destinationURL: URL) throws {
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &error) { (zipURL) in
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: zipURL, to: destinationURL)
            } catch {
                print("Error creating zip: \(error)")
            }
        }
        
        if let error = error {
            throw error
        }
    }
} 