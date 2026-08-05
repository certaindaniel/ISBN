import SwiftUI

/// 解鎖無限書籍 paywall。
struct PaywallView: View {
    @EnvironmentObject var purchase: PurchaseService
    @ObservedObject private var locale = LocaleManager.shared
    private var s: Strings { locale.strings }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if purchase.isUnlocked {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundColor(.green)
                    Text(s.t("paywall_unlocked")).font(.title3)
                } else {
                    Image(systemName: "auto.stories").font(.system(size: 72)).foregroundColor(.accentColor)
                    Text(s.paywallSubtitle(PurchaseService.freeBookLimit))
                        .font(.headline).multilineTextAlignment(.center)

                    featureRow("infinity", s.t("paywall_feature_unlimited"))
                    featureRow("chart.line.uptrend", s.t("paywall_feature_profit"))
                    featureRow("lock.open", s.t("paywall_feature_once"))

                    if let lastError = purchase.lastError {
                        Text(lastError).font(.footnote).foregroundColor(.red)
                    }

                    Button {
                        Task { await purchase.buy() }
                    } label: {
                        if purchase.purchasePending {
                            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 12)
                        } else {
                            Text(purchase.product != nil ? s.paywallBuy(priceText()) : s.t("paywall_unavailable"))
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(purchase.product == nil || purchase.purchasePending)

                    Button(s.t("paywall_restore")) {
                        Task { await purchase.restore() }
                    }
                    .disabled(purchase.purchasePending)
                }
            }
            .padding(24)
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.accentColor)
            Text(text).foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func priceText() -> String {
        guard let product = purchase.product else { return "" }
        return product.displayPrice
    }
}
