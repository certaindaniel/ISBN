import SwiftUI
import UIKit

/// 編輯目標包裝，讓 nil（新增）也能作為 sheet item。
struct EditTarget: Identifiable {
    let id = UUID()
    let book: Book?
}

/// 書籍列表主畫面。
struct BookListView: View {
    @EnvironmentObject var store: BookStore
    @ObservedObject private var locale = LocaleManager.shared
    @State private var filterStatus = "all"
    @State private var editTarget: EditTarget?
    @State private var showScanner = false
    @State private var showTitleSearch = false
    @State private var showSettings = false
    @State private var showAddSheet = false

    private var s: Strings { locale.strings }

    private var filteredBooks: [Book] {
        switch filterStatus {
        case "unread": return store.books.filter { $0.status == "unread" }
        case "reading": return store.books.filter { $0.status == "reading" }
        case "read": return store.books.filter { $0.status == "read" }
        default: return store.books
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if store.error != nil { errorBanner }
                filterSection
                if filteredBooks.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredBooks) { book in
                        BookRow(book: book,
                                onEdit: { editTarget = EditTarget(book: book) },
                                onDelete: { confirmDelete(book) })
                            .contentShape(Rectangle())
                            .onTapGesture { editTarget = EditTarget(book: book) }
                    }
                }
            }
            .navigationTitle(s.t("my_books_title"))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showTitleSearch = true
                    } label: {
                        Label(s.t("search_by_title_title"), systemImage: "magnifyingglass")
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .overlay {
                if store.isLoading { loadingOverlay }
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView()
            }
            .sheet(item: $editTarget) { target in
                BookEditView(initialBook: target.book)
            }
            .sheet(isPresented: $showTitleSearch) {
                TitleSearchSheet(onSelect: { book in
                    showTitleSearch = false
                    editTarget = EditTarget(book: book)
                }, onManualIsbn: { isbn in
                    Task { await searchAndEdit(isbn) }
                })
            }
            .overlay(alignment: .bottomTrailing) {
                if store.books.isEmpty && !store.isLoading {
                    addButton
                }
            }
        }
        .alert(s.t("delete_confirm_title"), isPresented: Binding(
            get: { bookToDelete != nil },
            set: { if !$0 { bookToDelete = nil } }
        )) {
            Button(s.t("delete_action"), role: .destructive) {
                if let book = bookToDelete, let id = book.id {
                    Task { await store.deleteBook(id: id) }
                }
                bookToDelete = nil
            }
            Button(s.t("cancel"), role: .cancel) { bookToDelete = nil }
        } message: {
            Text(s.t("delete_confirm_content"))
        }
        .task { await store.loadBooks() }
    }

    // MARK: - 子視圖

    private var errorBanner: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
            Text(store.errorCode != nil ? store.localizedError(s) : store.error ?? "")
                .foregroundColor(.red)
                .font(.subheadline)
            Spacer()
            Button {
                store.clearError()
            } label: {
                Image(systemName: "xmark").foregroundColor(.red)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("all", s.t("filter_all"))
                filterChip("unread", s.t("filter_unread"))
                filterChip("reading", s.t("filter_reading"))
                filterChip("read", s.t("filter_read"))
            }
            .padding(.vertical, 4)
        }
    }

    private func filterChip(_ value: String, _ label: String) -> some View {
        Button {
            filterStatus = value
        } label: {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(filterStatus == value ? Color.accentColor : Color(.systemGray5)))
                .foregroundColor(filterStatus == value ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48)).foregroundColor(.gray)
            Text(s.t("filter_no_books")).font(.title3)
            Text(s.t("empty_hint")).font(.subheadline).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder private var addButton: some View {
        Menu {
            Button(s.t("search_by_title_title")) { showTitleSearch = true }
            Button(s.t("scan_title")) { showScanner = true }
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
        .padding(.trailing, 20).padding(.bottom, 16)
    }

    private func searchAndEdit(_ isbn: String) async {
        let book = await store.searchBookByIsbn(isbn, sources: enabledSources())
        if let book { editTarget = EditTarget(book: book) }
    }

    private func enabledSources() -> [ApiSource] {
        let defaults = UserDefaults.standard
        let stored = defaults.stringArray(forKey: "enabled_api_sources") ?? []
        if stored.isEmpty { return ApiSource.defaultEnabled() }
        return ApiSource.allCases.filter { stored.contains($0.rawValue) }
    }

    @State private var bookToDelete: Book?

    private func confirmDelete(_ book: Book) {
        bookToDelete = book
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
            VStack(spacing: 12) {
                ProgressView()
                Text(s.t("searching_title")).font(.subheadline)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
        }
        .ignoresSafeArea()
    }
}

/// 書籍列項目。
struct BookRow: View {
    @ObservedObject private var locale = LocaleManager.shared
    let book: Book
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    private var s: Strings { locale.strings }

    var body: some View {
        HStack(spacing: 12) {
            coverImage
                .frame(width: 44, height: 66)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray4)))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title.isEmpty ? s.t("unknown_title") : book.title)
                    .font(.headline)
                Text(book.author.isEmpty ? s.t("unknown_author") : book.author)
                    .font(.subheadline).foregroundColor(.secondary)
                HStack(spacing: 8) {
                    statusBadge
                    if let score = book.lexileScore {
                        HStack(spacing: 2) {
                            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 11)).foregroundColor(.blue)
                            Text(s.lexileLabel(score)).font(.caption).foregroundColor(.blue)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button(s.t("edit")) { onEdit() }
            Button(s.t("delete"), role: .destructive) { onDelete() }
        }
    }

    @ViewBuilder private var coverImage: some View {
        if let url = book.coverUrl {
            if url.hasPrefix("/") || url.hasPrefix("file://") {
                let path = url.replacingOccurrences(of: "file://", with: "")
                if let uiImage = UIImage(contentsOfFile: path) {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                } else {
                    Image(systemName: "book").foregroundColor(.gray)
                }
            } else {
                AsyncImage(url: URL(string: url)) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() }
                    else { Image(systemName: "book").foregroundColor(.gray) }
                }
            }
        } else {
            Image(systemName: "book").foregroundColor(.gray)
        }
    }

    private var statusBadge: some View {
        let color: Color = book.status == "read" ? .green : (book.status == "reading" ? .orange : .gray)
        let label = book.status == "read" ? s.t("filter_read") : (book.status == "reading" ? s.t("filter_reading") : s.t("filter_unread"))
        return Text(label)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color))
            .foregroundColor(.white)
    }
}
