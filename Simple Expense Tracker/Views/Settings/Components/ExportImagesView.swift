import SwiftUI

struct ExportImagesView: View {
    @Binding var date: Date
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    @State private var isExporting = false
    
    private let months = Calendar.current.monthSymbols
    private let years = Array(2020...2030)
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                // Month Menu
                Menu {
                    ForEach(months.indices, id: \.self) { index in
                        Button(action: {
                            let year = Calendar.current.component(.year, from: date)
                            let components = DateComponents(year: year, month: index + 1, day: 1)
                            if let newDate = Calendar.current.date(from: components) {
                                date = newDate
                            }
                        }) {
                            Text(months[index])
                        }
                    }
                } label: {
                    HStack {
                        Text(months[Calendar.current.component(.month, from: date) - 1])
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .frame(width: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                
                // Year Menu
                Menu {
                    ForEach(years, id: \.self) { year in
                        Button(action: {
                            let month = Calendar.current.component(.month, from: date)
                            let components = DateComponents(year: year, month: month, day: 1)
                            if let newDate = Calendar.current.date(from: components) {
                                date = newDate
                            }
                        }) {
                            Text(String(format: "%d", year))
                        }
                    }
                } label: {
                    HStack {
                        Text(String(format: "%d", Calendar.current.component(.year, from: date)))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .frame(width: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .padding(.top, 20)
            
            if isExporting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Export Receipt Images")
        .navigationBarItems(
            leading: Button("Cancel") {
                isPresented = false
            },
            trailing: Button("Export") {
                exportImages()
            }
        )
    }
    
    private func exportImages() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let zipURL = createZipFile() {
                DispatchQueue.main.async {
                    isExporting = false
                    presentShareSheet(url: zipURL)
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    // TODO: Show error alert
                }
            }
        }
    }
    
    private func createZipFile() -> URL? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        // Filter expenses for selected month
        let monthExpenses = expenseManager.expenses.filter { expense in
            let components = calendar.dateComponents([.month, .year], from: expense.date)
            return components.month == month && components.year == year
        }
        
        // Create temporary directory for images
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM_yyyy"
        let dirName = "Expense_Images_\(formatter.string(from: date))"
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(dirName)
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(dirName).zip")
        
        do {
            // Remove existing directory and zip file if they exist
            try? FileManager.default.removeItem(at: tempDir)
            try? FileManager.default.removeItem(at: zipURL)
            
            // Create temp directory
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            var hasFiles = false
            
            // Copy and rename images
            for expense in monthExpenses {
                if let imagePath = expense.receiptImagePath {
                    let sourcePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(imagePath)
                    
                    // Check if source file exists
                    guard FileManager.default.fileExists(atPath: sourcePath.path) else {
                        print("Image file not found: \(sourcePath.path)")
                        continue
                    }
                    
                    // Create formatted date string
                    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                    let dateStr = formatter.string(from: expense.date)
                    
                    // Create new filename with unique identifier
                    let uniqueID = UUID().uuidString.prefix(8)
                    let newFileName = "\(expense.category.rawValue)_\(dateStr)_\(uniqueID)_receipt.jpg"
                    let destinationURL = tempDir.appendingPathComponent(newFileName)
                    
                    // Copy the already-compressed image
                    try FileManager.default.copyItem(at: sourcePath, to: destinationURL)
                    hasFiles = true
                }
            }
            
            // Only create zip if we have files to include
            if hasFiles {
                // Create zip file
                try ZipManager.createZip(at: tempDir, to: zipURL)
                
                // Clean up temp directory
                try FileManager.default.removeItem(at: tempDir)
                
                return zipURL
            } else {
                // Clean up temp directory
                try? FileManager.default.removeItem(at: tempDir)
                print("No valid image files found to zip")
                return nil
            }
            
        } catch {
            print("Error creating zip file: \(error)")
            // Clean up temp directory in case of error
            try? FileManager.default.removeItem(at: tempDir)
            return nil
        }
    }
    
    private func presentShareSheet(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() else { return }
        
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            // Clean up the temporary file
            try? FileManager.default.removeItem(at: url)
        }
        
        viewController.present(activityVC, animated: true)
    }
}