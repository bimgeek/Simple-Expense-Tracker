import Foundation

extension String {
    var localized: String {
        let language = LanguageManager.shared.currentLanguage
        
        // If system language is selected, use system localization
        if language == .system {
            return NSLocalizedString(self, comment: "")
        }
        
        // Otherwise, force the selected language
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
        let bundle = path != nil ? Bundle(path: path!) : Bundle.main
        
        return NSLocalizedString(self, bundle: bundle ?? Bundle.main, comment: "")
    }
} 