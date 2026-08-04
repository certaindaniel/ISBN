import SwiftUI

/// ISBN API 測試畫面。
struct ApiTestView: View {
    @ObservedObject private var locale = LocaleManager.shared
    private var s: Strings { locale.strings }
    @State private var output = ""
    @State private var isRunning = false
    private let testIsbn = "9789868914766"

    var body: some View {
        VStack {
            Button {
                Task { await runTests() }
            } label: {
                if isRunning {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 12)
                } else {
                    Label(s.t("api_test_start"), systemImage: "play.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
            .padding(16)

            ScrollView {
                Text(output.isEmpty ? s.t("api_test_output_placeholder") : output)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
            .padding(16)
        }
        .navigationTitle(s.t("api_test_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addLog(_ msg: String) {
        output += msg + "\n"
    }

    private func runTests() async {
        output = ""
        isRunning = true
        addLog("╔══════════════════════════════════════════╗")
        addLog("║   ISBN API 測試工作                      ║")
        addLog("║   ISBN: \(testIsbn)                   ║")
        addLog("╚══════════════════════════════════════════╝\n")

        await testOne("Google Books", [.googleBooks])
        await testOne("Open Library", [.openLibrary])
        await testOne("Jike 免費 API", [.jikeFree])

        addLog("【測試 4】多來源查詢 (Google → Open Library)")
        addLog("─" + String(repeating: "─", count: 49))
        var attempted: [ApiSource] = []
        let multi = try? await ISBNService.searchByIsbn(testIsbn, sources: [.googleBooks, .openLibrary]) { src in
            attempted.append(src)
            addLog("嘗試來源: \(src.displayName)")
        }
        if let book = multi {
            addLog("✓ 成功\n  書名: \(book.title)\n  ISBN: \(book.isbn)")
        } else {
            addLog("✗ 所有來源均失敗")
        }

        addLog("【測試 5】所有預設來源")
        addLog("─" + String(repeating: "─", count: 49))
        let defaults = ApiSource.defaultEnabled()
        addLog("啟用的來源: \(defaults.map(\.displayName).joined(separator: ", "))\n")
        let all = try? await ISBNService.searchByIsbn(testIsbn, sources: defaults) { src in
            addLog("嘗試來源: \(src.displayName)")
        }
        if let book = all {
            addLog("✓ 成功\n  書名: \(book.title)\n  ISBN: \(book.isbn)")
        } else {
            addLog("✗ 所有來源均失敗")
        }

        addLog("╔══════════════════════════════════════════╗")
        addLog("║        測試完成                        ║")
        addLog("╚══════════════════════════════════════════╝\n")
        isRunning = false
    }

    private func testOne(_ name: String, _ sources: [ApiSource]) async {
        addLog("【測試】\(name)")
        addLog("─" + String(repeating: "─", count: 49))
        let book = try? await ISBNService.searchByIsbn(testIsbn, sources: sources) { src in
            addLog("嘗試來源: \(src.displayName)")
        }
        if let book {
            addLog("✓ 成功")
            addLog("  書名: \(book.title)")
            addLog("  作者: \(book.author)")
            addLog("  出版社: \(book.publisher)")
            addLog("  ISBN: \(book.isbn)")
            addLog("  封面: \(book.coverUrl != nil ? "有" : "無")\n")
        } else {
            addLog("✗ 未返回結果\n")
        }
    }
}
