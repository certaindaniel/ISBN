import SwiftUI

@main
@MainActor
struct ISBNManagerApp: App {
    @StateObject private var store = BookStore()
    @StateObject private var locale = LocaleManager.shared
    @StateObject private var purchase = PurchaseService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(locale)
                .environmentObject(purchase)
        }
    }
}
