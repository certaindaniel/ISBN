import SwiftUI

/// 主畫面：書籍列表與統計的 TabView。
struct RootView: View {
    @ObservedObject private var locale = LocaleManager.shared

    var body: some View {
        TabView {
            BookListView()
                .tabItem {
                    Label(locale.strings.t("books"), systemImage: "books.vertical")
                }
            StatisticsView()
                .tabItem {
                    Label(locale.strings.t("statistics"), systemImage: "chart.bar")
                }
        }
    }
}
