import SwiftUI

/// 統計報表畫面（閱讀/金額兩個分頁）。
struct StatisticsView: View {
    @EnvironmentObject var store: BookStore
    @ObservedObject private var locale = LocaleManager.shared
    @State private var selectedTab = 0
    @State private var goalText = ""
    private var s: Strings { locale.strings }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text(s.t("statistics_tab_reading")).tag(0)
                    Text(s.t("statistics_tab_finance")).tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if selectedTab == 0 {
                    readingTab
                } else {
                    financeTab
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(s.t("statistics_title"))
            .navigationBarTitleDisplayMode(.inline)
            .task { await store.loadStatistics() }
        }
    }

    private var readingTab: some View {
        ScrollView {
            VStack(spacing: 16) {
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

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(s.t("goals_title")).font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    TextField(s.t("goals_hint"), text: $goalText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                        .onSubmit { saveGoal(goalText) }
                    Text(s.t("books")).font(.subheadline).foregroundColor(.secondary)
                }
            }

            Text(s.goalsDone(done, goal))
                .font(.subheadline).foregroundColor(.secondary)

            ProgressView(value: min(percent, 1.0), total: 1.0)
                .tint(.appProfit)

            HStack {
                Text(String(format: s.t("goals_percent"), percent * 100))
                    .font(.caption).fontWeight(.semibold).foregroundColor(.appProfit)
                Spacer()
            }

            Divider()

            HStack {
                Image(systemName: "flame.fill").foregroundColor(.orange)
                Text(s.goalsStreakCurrent(current))
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(s.goalsStreakBest(best))
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCardBg).shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1))
    }

    private func saveGoal(_ text: String) {
        let goal = Int(text.trimmingCharacters(in: .whitespaces)) ?? 20
        Database.shared.setSetting("reading_goal_year", String(goal))
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(s.t("stat_overview_title")).font(.headline)
            HStack(spacing: 12) {
                statItem(s.t("stat_total_books"), store.statistics.totalBooks, "books.vertical.fill", .appAccent)
                statItem(s.t("stat_read"), store.statistics.readBooks, "checkmark.circle.fill", .appProfit)
                statItem(s.t("stat_reading"), store.statistics.readingBooks, "book.fill", .appReading)
                statItem(s.t("stat_unread"), store.statistics.unreadBooks, "circle", .gray)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCardBg).shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1))
    }

    private func statItem(_ label: String, _ value: Int, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 26)).foregroundColor(color)
            Text("\(value)").font(.title3.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.08)))
    }

    private var completionCard: some View {
        let total = store.statistics.totalBooks
        let read = store.statistics.readBooks
        let reading = store.statistics.readingBooks
        let unread = store.statistics.unreadBooks
        let percent = Double(read) / Double(total) * 100
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(s.t("stat_completion_title")).font(.headline)
                Spacer()
                Text(String(format: "%.1f%%", percent)).bold().foregroundColor(.appProfit)
            }

            HStack {
                Spacer()
                ZStack {
                    Circle().stroke(Color(.systemGray5), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: min(percent / 100, 1))
                        .stroke(Color.appProfit, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(String(format: "%.0f%%", percent)).font(.headline).bold().foregroundColor(.appProfit)
                }
                .frame(width: 76, height: 76)
                Spacer()
            }

            GeometryReader { geo in
                let totalW = geo.size.width
                let readW = total > 0 ? (CGFloat(read) / CGFloat(total)) * totalW : 0
                let readingW = total > 0 ? (CGFloat(reading) / CGFloat(total)) * totalW : 0
                let unreadW = total > 0 ? (CGFloat(unread) / CGFloat(total)) * totalW : 0

                HStack(spacing: 0) {
                    Rectangle().fill(Color.appProfit).frame(width: readW, height: 10)
                    Rectangle().fill(Color.appReading).frame(width: readingW, height: 10)
                    Rectangle().fill(Color(.systemGray4)).frame(width: unreadW, height: 10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .frame(height: 10)

            HStack {
                Text("\(s.t("stat_read")): \(read)").foregroundColor(.appProfit)
                Spacer()
                Text(s.statsReadingLabel(reading)).foregroundColor(.appReading)
                Spacer()
                Text(s.statsUnreadLabel(unread)).foregroundColor(.gray)
            }
            .font(.caption)
            .fontWeight(.medium)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCardBg).shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1))
    }

    private var financeTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(s.t("finance_title")).font(.headline)
                financeRow(s.t("finance_total_spent"), store.statistics.totalSpent, .appLoss)
                financeRow(s.t("finance_total_earned"), store.statistics.totalEarned, .appProfit)
                Divider()
                HStack {
                    Text(s.t("finance_total_profit")).font(.headline)
                    Spacer()
                    Text(String(format: "%.2f", store.statistics.totalProfit))
                        .font(.title2.bold())
                        .foregroundColor(store.statistics.totalProfit >= 0 ? .appProfit : .appLoss)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10).fill(store.statistics.totalProfit >= 0 ? Color.appProfit.opacity(0.1) : Color.appLoss.opacity(0.1)))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCardBg).shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1))
            .padding(16)
        }
    }

    private func financeRow(_ label: String, _ amount: Double, _ color: Color) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Text(String(format: "%.2f", amount)).font(.headline).bold().foregroundColor(color)
        }
    }
}

