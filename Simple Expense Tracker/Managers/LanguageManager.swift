import Foundation

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
        }
    }
    
    enum Language: String {
        case system = "system"
        case english = "en"
        case turkish = "tr"
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .english: return "English"
            case .turkish: return "Türkçe"
            }
        }
    }
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? Language.system.rawValue
        currentLanguage = Language(rawValue: savedLanguage) ?? .system
    }
} 