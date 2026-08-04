import Foundation
import StoreKit

/// Freemium：免費 20 本，非消耗型 IAP 解鎖無限書籍。
/// 解鎖狀態存本地 flag，無伺服器收據驗證。
@MainActor
final class PurchaseService: ObservableObject {
    static let shared = PurchaseService()
    static let productId = "com.daniel.isbn.unlimited"
    static let freeBookLimit = 20
    private static let unlockedKey = "iap_unlimited_unlocked"
    private static let firstFreeBuild = 10

    @Published var product: Product?
    @Published var storeAvailable = false
    @Published var purchasePending = false
    @Published var lastError: String?
    @Published private(set) var unlocked = false

    private var updates: Task<Void, Never>?

    private init() {
        Task { await loadInitialState() }
    }

    var isUnlocked: Bool { unlocked }

    private func loadInitialState() async {
        unlocked = UserDefaults.standard.bool(forKey: PurchaseService.unlockedKey)
        if !unlocked {
            await grandfatherPaidBuyers()
        }
        if let products = try? await Product.products(for: [PurchaseService.productId]) {
            storeAvailable = true
            product = products.first
            updates = observeTransactions()
        } else {
            storeAvailable = false
        }
    }

    /// 老買家豁免：freemium 從 build 10 開始，originalAppVersion < 10 且為 production 直接解鎖。
    private func grandfatherPaidBuyers() async {
        if #available(iOS 16.0, *) {
            do {
                let tx = try await AppTransaction.shared
                if case .verified(let appTransaction) = tx, appTransaction.environment == .production {
                    let build = Int(appTransaction.originalAppVersion.split(separator: ".").first ?? "0")
                    if let build, build < PurchaseService.firstFreeBuild {
                        unlocked = true
                        UserDefaults.standard.set(true, forKey: PurchaseService.unlockedKey)
                    }
                }
            } catch {}
        }
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result, transaction.productID == PurchaseService.productId {
            unlocked = true
            UserDefaults.standard.set(true, forKey: PurchaseService.unlockedKey)
            await transaction.finish()
        }
    }

    func buy() async {
        guard let product, !purchasePending else { return }
        lastError = nil
        purchasePending = true
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled:
                lastError = nil
            case .pending:
                lastError = nil
            default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
        purchasePending = false
    }

    func restore() async {
        guard !purchasePending else { return }
        purchasePending = true
        do {
            for await result in Transaction.all {
                await handle(result)
            }
        } catch {
            lastError = error.localizedDescription
        }
        purchasePending = false
    }
}
