import SwiftUI

/// 解鎖無限書籍 paywall。
struct PaywallView: View {
    @EnvironmentObject var purchase: PurchaseService
    @ObservedObject private var locale = LocaleManager.shared
    private var s: Strings { locale.strings }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if purchase.isUnlocked {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.appProfit)
                        Text(s.t("paywall_unlocked"))
                            .font(.title2).fontWeight(.bold)
                    }
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color.appAccent.opacity(0.12))
                                .frame(width: 100, height: 100)
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.appAccent)
                        }

                        Text(s.paywallSubtitle(PurchaseService.freeBookLimit))
                            .font(.title3).fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                    }

                    VStack(spacing: 12) {
                        featureRow("infinity.circle.fill", s.t("paywall_feature_unlimited"))
                        featureRow("chart.line.uptrend.xyaxis.circle.fill", s.t("paywall_feature_profit"))
                        featureRow("lock.open.circle.fill", s.t("paywall_feature_once"))
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.appCardBg))

                    if let lastError = purchase.lastError {
                        Text(lastError)
                            .font(.footnote)
                            .foregroundColor(.appLoss)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task { await purchase.buy() }
                        } label: {
                            if purchase.purchasePending {
                                ProgressView().tint(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            } else {
                                Text(purchase.product != nil ? s.paywallBuy(priceText()) : s.t("paywall_unavailable"))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.appAccent))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.appAccent.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                        }
                        .disabled(purchase.product == nil || purchase.purchasePending)

                        Button(s.t("paywall_restore")) {
                            Task { await purchase.restore() }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .disabled(purchase.purchasePending)
                    }
                }
            }
            .padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.appAccent)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func priceText() -> String {
        guard let product = purchase.product else { return "" }
        return product.displayPrice
    }
}

