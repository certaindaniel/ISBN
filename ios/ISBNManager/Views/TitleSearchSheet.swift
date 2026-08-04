import SwiftUI

/// 以書名查詢 bottom sheet。
struct TitleSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var locale = LocaleManager.shared
    var onSelect: (Book) -> Void = { _ in }
    var onManualIsbn: (String) -> Void = { _ in }

    @State private var title = ""
    @State private var author = ""
    @State private var results: [Book] = []
    @State private var loading = false
    @State private var toast: String?
    @State private var showManual = false
    @State private var manualIsbn = ""

    private var s: Strings { locale.strings }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField(s.t("label_title_required"), text: $title)
                    .textFieldStyle(.roundedBorder)
                TextField(s.t("author_optional"), text: $author)
                    .textFieldStyle(.roundedBorder)
                Button {
                    doSearch()
                } label: {
                    Label(s.t("search_button"), systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
                        .foregroundColor(.white)
                }
                .disabled(loading)

                if loading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if results.isEmpty {
                    VStack(spacing: 8) {
                        Text(s.t("no_results_text")).foregroundColor(.gray)
                        Button(s.t("manual_isbn_label")) { showManual = true }
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                } else {
                    List(results) { book in
                        Button {
                            onSelect(book)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title.isEmpty ? s.t("unknown_title") : book.title).font(.headline)
                                Text("\(book.author.isEmpty ? s.t("unknown_author") : book.author) • ISBN: \(book.isbn)")
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .navigationTitle(s.t("search_by_title_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(s.t("cancel")) { confirmClose() }
                }
            }
            .sheet(isPresented: $showManual) { manualSheet }
            .overlay(alignment: .top) {
                if let toast {
                    Text(toast).font(.footnote).padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.8)).foregroundColor(.white)).padding(.top, 8)
                }
            }
        }
    }

    private var manualSheet: some View {
        NavigationStack {
            Form {
                TextField(s.t("manual_isbn_hint"), text: $manualIsbn)
                    .keyboardType(.numberPad)
            }
            .navigationTitle(s.t("manual_isbn_title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(s.t("search_button")) {
                        let isbn = manualIsbn.trimmingCharacters(in: .whitespaces)
                        showManual = false
                        dismiss()
                        onManualIsbn(isbn)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(s.t("cancel")) { showManual = false }
                }
            }
        }
    }

    private func doSearch() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else {
            toast = s.t("please_enter_title")
            return
        }
        loading = true
        Task {
            results = await ISBNService.searchByTitleAuthor(t, author: author.isEmpty ? nil : author)
            loading = false
        }
    }

    private func confirmClose() {
        let hasChanges = !title.isEmpty || !author.isEmpty || !results.isEmpty || loading
        if hasChanges { dismiss() } else { dismiss() }
    }
}
