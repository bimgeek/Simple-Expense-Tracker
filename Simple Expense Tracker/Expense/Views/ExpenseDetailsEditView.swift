import SwiftUI

struct ExpenseDetailsEditView: View {
    let expense: Expense
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line
    
    @State private var amount: String = ""
    @State private var memo: String = ""
    @State private var selectedDateOption: DateOption = .today
    @State private var vatAmount: String = ""
    @State private var showingDatePicker = false
    @State private var showingDeleteAlert = false
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isVATFocused: Bool
    @FocusState private var isMemoFocused: Bool
    @State private var receiptImage: UIImage?
    @State private var showingCamera = false
    @State private var showingFullScreenImage = false
    @State private var shouldDeleteImage = false
    @State private var showMemoSuggestions = false  // Add this line
    
    // Add category property
    private let category: ExpenseCategory
    
    init(expense: Expense, expenseManager: ExpenseManager, isPresented: Binding<Bool>) {
        self.expense = expense
        self.expenseManager = expenseManager
        self._isPresented = isPresented
        self.category = expense.category  // Initialize category from expense
        
        // Initialize state with expense values
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _vatAmount = State(initialValue: String(format: "%.2f", expense.vat))
        _memo = State(initialValue: expense.memo)
        _selectedDateOption = State(initialValue: .custom(expense.date))
    }
    
    private func formatNumberString(_ input: String) -> String {
        let sanitized = input.replacingOccurrences(of: ",", with: ".")
        let components = sanitized.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        return sanitized
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDateOption.date)
    }
    
    private var memoSuggestions: [String] {
        guard !memo.isEmpty else { return [] }
        return expenseManager.previousMemos(for: category, startingWith: memo)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.01)
                    .onTapGesture {
                        isAmountFocused = false
                        isVATFocused = false
                        isMemoFocused = false
                    }
                
                VStack(spacing: 24) {
                    // Category Chip
                    HStack(spacing: 8) {
                        Image(systemName: expense.category.icon)
                        Text(expense.category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").localized)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.top)
                    
                    // Amount Input
                    VStack(spacing: 16) {
                        ZStack {
                            HStack(spacing: 4) {
                                Text(currencyManager.currentCurrency.symbol)
                                    .font(.system(size: 72, weight: .regular))
                                TextField("0", text: Binding(
                                    get: { amount },
                                    set: { amount = formatNumberString($0) }
                                ))
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 72, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.5)
                                    .frame(maxWidth: 400)
                                    .focused($isAmountFocused)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .padding(.horizontal, 20)
                        
                        // VAT Input
                        TextField("vat".localized, text: Binding(
                            get: { vatAmount },
                            set: { vatAmount = formatNumberString($0) }
                        ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .focused($isVATFocused)
                        
                        // Memo Input
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("memo".localized, text: $memo)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .focused($isMemoFocused)
                                .onChange(of: memo) { newValue in
                                    showMemoSuggestions = !newValue.isEmpty
                                }
                            
                            // Add MemoSuggestionView if there are suggestions
                            if showMemoSuggestions && !memoSuggestions.isEmpty {
                                MemoSuggestionView(
                                    suggestions: memoSuggestions,
                                    onSelect: { selectedMemo in
                                        memo = selectedMemo
                                        showMemoSuggestions = false
                                    }
                                )
                            }
                        }
                        
                        // Date Selection
                        HStack {
                            Text("date".localized + ":")
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                Text(formattedDate)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Receipt Image Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("receipt".localized)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            if let image = receiptImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                    .overlay(
                                        Button(action: { receiptImage = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .padding(8)
                                        }
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(8),
                                        alignment: .topTrailing
                                    )
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        showingFullScreenImage = true
                                    }
                            }
                            
                            Button(action: {
                                showingCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text(receiptImage == nil ? "take_photo".localized : "retake_photo".localized)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.0, green: 0.478, blue: 1.0))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarItems(
                leading: Button("delete".localized) {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red),
                trailing: Button("done".localized) {
                    // Add this code to save changes
                    if let amountDouble = Double(amount),
                       let vatDouble = Double(vatAmount) {
                        // Save image if exists
                        var imagePath = expense.receiptImagePath
                        if let image = receiptImage {
                            imagePath = ImageManager.shared.saveImage(image, forExpense: expense.id)
                        }
                        
                        expenseManager.updateExpense(
                            expense,
                            newAmount: amountDouble,
                            newVat: vatDouble,
                            newMemo: memo,
                            newDate: selectedDateOption.date,
                            receiptImagePath: imagePath
                        )
                    }
                    isPresented = false
                }
            )
            .alert("delete_expense".localized, isPresented: $showingDeleteAlert) {
                Button("cancel".localized, role: .cancel) { }
                Button("delete".localized, role: .destructive) {
                    expenseManager.deleteExpense(expense)
                    isPresented = false
                }
            } message: {
                Text("delete_expense_warning".localized)
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationView {
                    DatePicker("", selection: Binding(
                        get: {
                            if case .custom(let date) = selectedDateOption {
                                return date
                            }
                            return Date()
                        },
                        set: { newDate in
                            selectedDateOption = .custom(newDate)
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .navigationBarItems(
                        trailing: Button("done".localized) {
                            showingDatePicker = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $receiptImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingFullScreenImage) {
                if let image = receiptImage {
                    FullScreenImageView(
                        image: image,
                        isPresented: $showingFullScreenImage,
                        shouldDeleteImage: $shouldDeleteImage
                    )
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .onChange(of: shouldDeleteImage) { shouldDelete in
                if shouldDelete {
                    receiptImage = nil
                }
            }
            .onAppear {
                if let imagePath = expense.receiptImagePath {
                    receiptImage = ImageManager.shared.loadImage(filename: imagePath)
                }
            }
        }
    }
}