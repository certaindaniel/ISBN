import StoreKit
import UIKit

/// 在成功新增書籍累積 5 次後請求 App Store 評分；設定頁可直接開商店評論頁。
enum ReviewService {
    private static let countKey = "review_success_count"
    private static let promptedKey = "review_prompted"
    private static let threshold = 5
    private static let appStoreId = "6756864904"

    static func recordSuccess() async {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: promptedKey) { return }
        let count = (defaults.integer(forKey: countKey)) + 1
        defaults.set(count, forKey: countKey)
        if count < threshold { return }
        defaults.set(true, forKey: promptedKey)
        await requestReview()
    }

    static func requestReview() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        await SKStoreReviewController.requestReview(in: scene)
    }

    static func openStoreListing() async {
        let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)")!
        await UIApplication.shared.open(url)
    }
}
