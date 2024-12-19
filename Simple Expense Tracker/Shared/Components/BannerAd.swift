import SwiftUI
import GoogleMobileAds

struct BannerAd: UIViewRepresentable {
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ID
    #else
    private let adUnitID = Config.adUnitID // Production ID from Config
    #endif
    
    init() { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        bannerView.delegate = context.coordinator
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Banner ad loaded successfully")
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed to load with error: \(error.localizedDescription)")
        }
    }
} 