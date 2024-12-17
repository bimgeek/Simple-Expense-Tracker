import SwiftUI

struct ExpenseDetailsView: View {
    let category: ExpenseCategory
    @ObservedObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line
    
    @State private var amount: String = ""
    @State private var memo: String = ""
    @State private var showingDatePicker = false
    @State private var selectedDateOption: DateOption = .today
    @State private var vatAmount: String = ""
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isVATFocused: Bool
    @FocusState private var isMemoFocused: Bool
    @State private var showMemoSuggestions = false
    @State private var showingCamera = false
    @State private var receiptImage: UIImage?
    @State private var showingFullScreenImage = false
    @State private var shouldDeleteImage = false
    
    private func formatNumberString(_ input: String) -> String {
        // Replace comma with period for consistency
        let sanitized = input.replacingOccurrences(of: ",", with: ".")
        
        // Only allow one decimal separator
        let components = sanitized.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        
        return sanitized
    }
    
    private var memoSuggestions: [String] {
        guard !memo.isEmpty else { return [] }
        return expenseManager.previousMemos(for: category, startingWith: memo)
    }
    
    var body: some View {
        NavigationView {
            ZStack {  // Add ZStack to layer tap gesture
                Color.black.opacity(0.01)  // Nearly transparent background for tap detection
                    .onTapGesture {
                        isAmountFocused = false  // Dismiss keyboard
                        isVATFocused = false
                        isMemoFocused = false
                    }
                
                VStack(spacing: 24) {
                    // Category Chip
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                        Text(category.localizedName)  // Change this line
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
                leading: Button("cancel".localized) {
                    isPresented = false
                },
                trailing: Button("add_expense".localized) {
                    if let amountDouble = Double(amount),
                       amountDouble > 0 {
                        let vatDouble = Double(vatAmount) ?? 0
                        
                        // Save image if exists
                        var imagePath: String? = nil
                        if let image = receiptImage {
                            imagePath = ImageManager.shared.saveImage(image, forExpense: UUID())
                        }
                        
                        let expense = Expense(
                            amount: amountDouble,
                            vat: vatDouble,
                            category: category,
                            memo: memo,
                            date: selectedDateOption.date,
                            receiptImagePath: imagePath
                        )
                        expenseManager.addExpense(expense)
                        isPresented = false
                    }
                }
                .disabled(amount.isEmpty || Double(amount) == 0)
            )
            .background(Color.black.edgesIgnoringSafeArea(.all))
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
                // Activate the amount field when the view appears
                // Adding a slight delay ensures the focus works reliably
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAmountFocused = true
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        // Set locale based on selected language
        switch LanguageManager.shared.currentLanguage {
        case .turkish:
            formatter.locale = Locale(identifier: "tr")
        case .english:
            formatter.locale = Locale(identifier: "en")
        case .system:
            formatter.locale = Locale.current
        }
        return formatter.string(from: selectedDateOption.date)
    }
}