import SwiftUI

struct SettingsView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared  // Add this line
    @State private var showingResetAlert = false
    @State private var showingConfirmationAlert = false
    @State private var showingSuccessMessage = false
    @State private var showingExportPicker = false
    @State private var selectedExportDate = Date()
    @State private var showingImageExportPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 24) {
                    // Language settings group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("language".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Menu {
                            ForEach([LanguageManager.Language.system,
                                   .english,
                                   .turkish], id: \.self) { language in
                                Button(action: {
                                    languageManager.currentLanguage = language
                                }) {
                                    HStack {
                                        Text(language.displayName)
                                        if languageManager.currentLanguage == language {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text(languageManager.currentLanguage.displayName)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.cyan)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Currency settings group (add this section)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("currency".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Menu {
                            ForEach(Currency.allCases, id: \.self) { currency in
                                Button(action: {
                                    currencyManager.currentCurrency = currency
                                }) {
                                    HStack {
                                        Text(currency.localizedName)
                                        if currencyManager.currentCurrency == currency {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                Text(currencyManager.currentCurrency.localizedName)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.cyan)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical)

                    // Export options group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("export_description".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingExportPicker = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("export_expenses".localized)
                                Spacer()
                            }
                            .foregroundColor(.cyan)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            showingImageExportPicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("export_images".localized)
                                Spacer()
                            }
                            .foregroundColor(.cyan)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical)
                    
                    // Reset data group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("reset_warning".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("reset_all_data".localized)
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color(red: 0.1, green: 0.1, blue: 0.3))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Version text
                    HStack {
                        Spacer()
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"))")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, 60)
                    
                    Spacer()
                }
                .padding(.top)
                .navigationTitle("settings".localized)
                
                // Success message overlay
                if showingSuccessMessage {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("data_reset_success".localized)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("reset_all_data".localized, isPresented: $showingResetAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("reset".localized, role: .destructive) {
                showingConfirmationAlert = true
            }
        } message: {
            Text("reset_warning".localized)
        }
        .alert("reset_confirm".localized, isPresented: $showingConfirmationAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("yes_reset".localized, role: .destructive) {
                expenseManager.resetAllData()
                withAnimation {
                    showingSuccessMessage = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showingSuccessMessage = false
                    }
                }
            }
        } message: {
            Text("reset_confirm".localized)
        }
        .sheet(isPresented: $showingExportPicker) {
            NavigationView {
                ExportPickerView(
                    date: $selectedExportDate,
                    expenseManager: expenseManager,
                    isPresented: $showingExportPicker
                )
            }
        }
        .sheet(isPresented: $showingImageExportPicker) {
            NavigationView {
                ExportImagesView(
                    date: $selectedExportDate,
                    expenseManager: expenseManager,
                    isPresented: $showingImageExportPicker
                )
            }
        }
    }
}