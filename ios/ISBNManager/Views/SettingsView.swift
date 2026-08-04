import SwiftUI

/// 設定畫面。
struct SettingsView: View {
    @EnvironmentObject var purchase: PurchaseService
    @ObservedObject private var locale = LocaleManager.shared
    @State private var showPaywall = false
    @State private var showApiTest = false

    private var s: Strings { locale.strings }

    private var enabledCount: Int {
        ApiSource.allCases.filter { isEnabled($0) }.count
    }

    var body: some View {
        List {
            languageSection
            sourcesSection
            keySection
            websitesSection
            purchaseSection
            rateSection
            syncSection
        }
        .navigationTitle(s.t("settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showApiTest = true } label: { Image(systemName: "ladybug") }
            }
        }
        .navigationDestination(isPresented: $showApiTest) { ApiTestView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - 動態多國語

    private var languageSection: some View {
        Section(s.t("language_section_title")) {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    locale.set(lang)
                } label: {
                    HStack {
                        Text(lang.displayName).foregroundColor(.primary)
                        Spacer()
                        if locale.language == lang {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 查詢來源

    private var sourcesSection: some View {
        Section(s.settingsEnabledSources(enabledCount, ApiSource.allCases.count)) {
            ForEach(ApiSource.allCases) { source in
                Toggle(source.localizedName(s), isOn: binding(for: source))
            }
            Text(s.t("settings_sources_subtitle")).font(.footnote).foregroundColor(.secondary)
            Text(s.t("settings_sources_explain")).font(.footnote).foregroundColor(.secondary)
        }
    }

    // MARK: - API Key（選填）

    private var keySection: some View {
        Section(s.t("settings_keys_title")) {
            ForEach(ApiSource.allCases.filter { $0.requiresKey }) { source in
                TextField(s.t("settings_key_placeholder"),
                          text: keyBinding(for: source))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            Text(s.t("settings_keys_explain")).font(.footnote).foregroundColor(.secondary)
        }
    }

    private func keyBinding(for source: ApiSource) -> Binding<String> {
        let key = source.keyStorageKey ?? ""
        return Binding(get: {
            UserDefaults.standard.string(forKey: key) ?? ""
        }, set: { newValue in
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespaces), forKey: key)
        })
    }

    private func binding(for source: ApiSource) -> Binding<Bool> {
        Binding(get: { isEnabled(source) },
                set: { newValue in
                    var enabled = UserDefaults.standard.stringArray(forKey: "enabled_api_sources") ?? []
                    if newValue { enabled.append(source.rawValue) }
                    else { enabled.removeAll { $0 == source.rawValue } }
                    UserDefaults.standard.set(enabled, forKey: "enabled_api_sources")
                })
    }

    private func isEnabled(_ source: ApiSource) -> Bool {
        let stored = UserDefaults.standard.stringArray(forKey: "enabled_api_sources") ?? []
        if stored.isEmpty { return source.enabledByDefault }
        return stored.contains(source.rawValue)
    }

    // MARK: - 常用查詢網頁

    private var websitesSection: some View {
        Section(s.t("settings_common_websites_title")) {
            if isZh {
                websiteRow(s.t("settings_tnla_title"), s.t("settings_tnla_subtitle"), "globe", "https://isbn.ncl.edu.tw/NEW_ISBNNet/main_DisplayResults.php?Pact=DisplayAll4Simple")
                websiteRow(s.t("settings_bok_title"), s.t("settings_bok_subtitle"), "book", "https://www.books.com.tw/")
                websiteRow(s.t("settings_eslite_title"), s.t("settings_eslite_subtitle"), "books.vertical", "https://www.eslite.com/")
            } else {
                websiteRow(s.t("settings_openlibrary_title"), s.t("settings_openlibrary_subtitle"), "globe", "https://openlibrary.org/")
            }
            websiteRow(s.t("settings_google_title"), s.t("settings_google_subtitle"), "magnifyingglass", "https://books.google.com/")
        }
    }

    private var isZh: Bool {
        locale.strings.language != .english
    }

    private func websiteRow(_ title: String, _ subtitle: String, _ icon: String, _ url: String) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack {
                Image(systemName: icon).foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text(title).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square").foregroundColor(.secondary)
            }
        }
    }

    private func openURL(_ str: String) {
        guard let url = URL(string: str) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - 解鎖與評分

    private var purchaseSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: purchase.isUnlocked ? "checkmark.seal" : "lock.open").foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text(purchase.isUnlocked ? s.t("paywall_unlocked") : s.t("settings_unlock_title"))
                            .foregroundColor(.primary)
                        if !purchase.isUnlocked {
                            Text(s.settingsUnlockSubtitle(PurchaseService.freeBookLimit)).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
            }
            .disabled(purchase.isUnlocked)
        }
    }

    private var rateSection: some View {
        Section {
            Button {
                Task { await ReviewService.openStoreListing() }
            } label: {
                HStack {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    VStack(alignment: .leading) {
                        Text(s.t("settings_rate_title")).foregroundColor(.primary)
                        Text(s.t("settings_rate_subtitle")).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - iCloud 同步

    private var syncSection: some View {
        Section {
            Button {
                Task { await runSync() }
            } label: {
                HStack {
                    Image(systemName: "icloud").foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text(s.t("sync_title")).foregroundColor(.primary)
                        Text(s.t("sync_subtitle")).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if let msg = syncMessage {
                        Button {
                            copyMessage(msg)
                        } label: {
                            Text(msg).font(.caption).foregroundColor(msg == s.t("sync_success") ? .green : .red)
                        }
                    }
                }
            }
        }
    }

    private func copyMessage(_ msg: String) {
        UIPasteboard.general.string = msg
    }

    @State private var syncMessage: String?

    private func runSync() async {
        let error = await SyncService.shared.sync()
        if error == nil {
            syncMessage = s.t("sync_success")
        } else {
            syncMessage = error
        }
    }
}
