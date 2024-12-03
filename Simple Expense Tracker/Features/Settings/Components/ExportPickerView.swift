import SwiftUI

struct ExportPickerView: View {
    @Binding var date: Date
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    @State private var csvURL: URL?
    
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
            
            Spacer()
        }
        .navigationTitle("Export Expenses")
        .navigationBarItems(
            leading: Button("Cancel") {
                isPresented = false
            },
            trailing: Button("Export") {
                if let url = generateCSV() {
                    presentShareSheet(url: url)
                }
            }
        )
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
    
    private func generateCSV() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        // Get the month's expenses
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let monthExpenses = expenseManager.expenses.filter { expense in
            let components = calendar.dateComponents([.month, .year], from: expense.date)
            return components.month == month && components.year == year
        }
        
        // Create CSV content
        var csvContent = "Date,Category,Amount,VAT,Memo\n"
        
        for expense in monthExpenses.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: expense.date)
            let category = expense.category.rawValue
            let amount = String(format: "%.2f", expense.amount)
            let vat = String(format: "%.2f", expense.vat)
            let memo = expense.memo.replacingOccurrences(of: ",", with: ";") // Escape commas in memo
            
            csvContent += "\(date),\(category),\(amount),\(vat),\(memo)\n"
        }
        
        // Create temporary file
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM_yyyy"
        let fileName = "expenses_\(formatter.string(from: date)).csv"
        
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV file: \(error)")
            return nil
        }
    }
}