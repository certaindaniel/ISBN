import SwiftUI

/// 統計報表畫面（閱讀/金額兩個分頁）。
struct StatisticsView: View {
    @EnvironmentObject var store: BookStore
    @ObservedObject private var locale = LocaleManager.shared
    @State private var goalText = ""
    private var s: Strings { locale.strings }

    var body: some View {
        TabView {
            readingTab.tabItem { Label(s.t("statistics_tab_reading"), systemImage: "book") }
            financeTab.tabItem { Label(s.t("statistics_tab_finance"), systemImage: "dollarsign.circle") }
        }
        .navigationTitle(s.t("statistics_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadStatistics() }
    }

    private var readingTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                overviewCard
                goalsCard
                if store.statistics.totalBooks > 0 { completionCard }
            }
            .padding(16)
            .onAppear {
                goalText = Database.shared.getSetting("reading_goal_year") ?? ""
            }
        }
    }

    // MARK: - 閱讀目標與連續天數

    private var goalsCard: some View {
        let goal = Int(goalText) ?? 20
        let done = Database.shared.finishedBooksThisYear()
        let percent = goal > 0 ? Double(done) / Double(goal) : 0
        let current = Database.shared.currentStreak()
        let best = Database.shared.bestStreak()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(s.t("goals_title")).font(.headline)
                Spacer()
                TextField(s.t("goals_hint"), text: $goalText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onSubmit { saveGoal(goalText) }
            }

            Text(s.goalsDone(done, goal))
                .font(.subheadline).foregroundColor(.secondary)

            ProgressView(value: min(percent, 1.0), total: 1.0)
                .tint(.green)

            Text(String(format: s.t("goals_percent"), percent * 100))
                .font(.caption).foregroundColor(.green)

            HStack {
                Image(systemName: "flame.fill").foregroundColor(.orange)
                Text(s.goalsStreakCurrent(current))
                    .font(.subheadline)
                Spacer()
                Text(s.goalsStreakBest(best))
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.1), radius: 2))
    }

    private func saveGoal(_ text: String) {
        let goal = Int(text.trimmingCharacters(in: .whitespaces)) ?? 20
        Database.shared.setSetting("reading_goal_year", String(goal))
    }

    private var overviewCard: some View {
        VStack(spacing: 20) {
            Text(s.t("stat_overview_title")).font(.headline)
            HStack {
                statItem(s.t("stat_total_books"), store.statistics.totalBooks, "books.vertical", .blue)
                statItem(s.t("stat_read"), store.statistics.readBooks, "checkmark.circle", .green)
                statItem(s.t("stat_reading"), store.statistics.readingBooks, "book", .orange)
                statItem(s.t("stat_unread"), store.statistics.unreadBooks, "circle", .gray)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.1), radius: 2))
    }

    private func statItem(_ label: String, _ value: Int, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 30)).foregroundColor(color)
            Text("\(value)").font(.title3.bold()).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var completionCard: some View {
        let total = store.statistics.totalBooks
        let read = store.statistics.readBooks
        let reading = store.statistics.readingBooks
        let unread = store.statistics.unreadBooks
        let percent = Double(read) / Double(total) * 100
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(s.t("stat_completion_title")).font(.headline)
                Spacer()
                Text(String(format: "%.1f%%", percent)).bold().foregroundColor(.green)
            }
            HStack {
                Spacer()
                ZStack {
                    Circle().stroke(Color(.systemGray5), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: min(percent / 100, 1))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(String(format: "%.0f%%", percent)).font(.headline).bold().foregroundColor(.green)
                }
                .frame(width: 72, height: 72)
                Spacer()
            }
            HStack(spacing: 0) {
                Rectangle().fill(Color.green).frame(width: CGFloat(read) / CGFloat(total) * 300, height: 10)
                Rectangle().fill(Color.orange).frame(width: CGFloat(reading) / CGFloat(total) * 300, height: 10)
                Rectangle().fill(Color(.systemGray4)).frame(width: CGFloat(unread) / CGFloat(total) * 300, height: 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            HStack {
                Text("\(s.t("stat_read")): \(read)").foregroundColor(.green)
                Spacer()
                Text(s.statsReadingLabel(reading)).foregroundColor(.orange)
                Spacer()
                Text(s.statsUnreadLabel(unread)).foregroundColor(.gray)
            }.font(.caption)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.1), radius: 2))
    }

    private var financeTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(s.t("finance_title")).font(.headline)
                financeRow(s.t("finance_total_spent"), store.statistics.totalSpent, .red)
                financeRow(s.t("finance_total_earned"), store.statistics.totalEarned, .green)
                Divider()
                HStack {
                    Text(s.t("finance_total_profit")).font(.headline)
                    Spacer()
                    Text(String(format: "%.2f", store.statistics.totalProfit))
                        .font(.title3.bold())
                        .foregroundColor(store.statistics.totalProfit >= 0 ? .green : .red)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(store.statistics.totalProfit >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1)))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.1), radius: 2))
            .padding(16)
        }
    }

    private func financeRow(_ label: String, _ amount: Double, _ color: Color) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: "%.2f", amount)).bold().foregroundColor(color)
        }
    }
}
