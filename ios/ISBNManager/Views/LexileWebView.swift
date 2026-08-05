import SwiftUI
import WebKit
import UIKit

/// WKWebView 包裝。
struct WebView: UIViewRepresentable {
    let url: URL
    var reloadTrigger = false

    func makeUIView(context: Context) -> WKWebView {
        let v = WKWebView()
        v.load(URLRequest(url: url))
        return v
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        if reloadTrigger { view.reload() }
    }
}

/// Lexile 查詢畫面。
struct LexileWebView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var locale = LocaleManager.shared
    let query: String
    var onPick: (Int) -> Void

    @State private var showManual = false
    @State private var manualText = ""
    @State private var toast: String?
    @State private var reloadTrigger = false

    private var s: Strings { locale.strings }

    var body: some View {
        NavigationStack {
            WebView(url: makeURL(), reloadTrigger: reloadTrigger)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(s.t("lexile_title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button { pasteFromClipboard() } label: { Image(systemName: "doc.on.clipboard") }
                            .accessibilityLabel(s.t("lexile_paste"))
                        Button { reloadTrigger.toggle() } label: { Image(systemName: "arrow.clockwise") }
                            .accessibilityLabel(s.t("lexile_reload"))
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button(s.t("lexile_manual_label")) { showManual = true }
                    }
                }
                .sheet(isPresented: $showManual) {
                    manualInputSheet
                }
                .overlay(alignment: .top) {
                    if let toast {
                        Text(toast).font(.footnote).padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.8)).foregroundColor(.white)).padding(.top, 8)
                    }
                }
        }
    }

    private func makeURL() -> URL {
        var comps = URLComponents(string: "https://hub.lexile.com/find-a-book/")!
        comps.queryItems = [URLQueryItem(name: "searchText", value: query)]
        return comps.url ?? URL(string: "https://hub.lexile.com/find-a-book/")!
    }

    private var manualInputSheet: some View {
        NavigationStack {
            Form {
                TextField(s.t("example_lexile_hint"), text: $manualText).keyboardType(.numberPad)
            }
            .navigationTitle(s.t("lexile_manual_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(s.t("lexile_fill")) {
                        if let v = Int(manualText.trimmingCharacters(in: .whitespaces)) {
                            onPick(v)
                            showManual = false
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(s.t("lexile_cancel")) { showManual = false }
                }
            }
        }
    }

    private func pasteFromClipboard() {
        let text = UIPasteboard.general.string ?? ""
        if let value = parseLexile(text) {
            onPick(value)
            dismiss()
        } else {
            toast = s.t("lexile_clipboard_none")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
        }
    }

    private func parseLexile(_ text: String) -> Int? {
        let lower = text.lowercased()
        let pattern = try? NSRegularExpression(pattern: #"lexile\s*:?\s*(\d+)\s*L"#)
        if let pattern, let match = pattern.firstMatch(in: lower, range: NSRange(location: 0, length: lower.utf16.count)),
           let range = Range(match.range(at: 1), in: lower),
           let v = Int(lower[range]) {
            return v
        }
        // 後備：第一個 2-5 位整數
        let p2 = try? NSRegularExpression(pattern: #"\d{2,5}"#)
        if let p2, let match = p2.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)),
           let range = Range(match.range, in: text),
           let v = Int(text[range]) {
            return v
        }
        return nil
    }
}
