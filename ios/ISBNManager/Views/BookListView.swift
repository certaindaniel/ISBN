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
    @State private var currentSource = ""

    private var s: Strings { locale.strings }

    private var filteredBooks: [Book] {
        switch filterStatus {
        case "unread": return store.books.filter { $0.status == "unread" }
        case "reading": return store.books.filter { $0.status == "reading" }
        case "read": return store.books.filter { $0.status == "read" }
        case "wishlist": return store.books.filter { $0.status == "wishlist" }
        default: return store.books
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.error != nil {
                    errorBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                filterSection
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemGroupedBackground))

                if filteredBooks.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredBooks) { book in
                            BookRow(book: book,
                                    onEdit: { editTarget = EditTarget(book: book) },
                                    onDelete: { confirmDelete(book) })
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { editTarget = EditTarget(book: book) }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .navigationTitle(s.t("my_books_title"))
            .navigationBarTitleDisplayMode(.inline)
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
                    .accessibilityLabel(s.t("settings_title"))
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
                if !store.isLoading {
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
            .accessibilityLabel(s.t("cancel"))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.12)))
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("all", s.t("filter_all"))
                filterChip("unread", s.t("filter_unread"))
                filterChip("reading", s.t("filter_reading"))
                filterChip("read", s.t("filter_read"))
                filterChip("wishlist", s.t("filter_wishlist"))
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(_ value: String, _ label: String) -> some View {
        let isSelected = filterStatus == value
        return Button {
            filterStatus = value
        } label: {
            Text(label)
                .font(.subheadline).fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.appAccent : Color(uiColor: .tertiarySystemFill)))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 56)).foregroundColor(.appAccent.opacity(0.8))
            Text(s.t("filter_no_books"))
                .font(.title3).fontWeight(.semibold)
            Text(s.t("empty_hint"))
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            HStack(spacing: 12) {
                Button(s.t("scan_title")) { showScanner = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.appAccent)
                Button(s.t("search_by_title_title")) { showTitleSearch = true }
                    .buttonStyle(.bordered)
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    @ViewBuilder private var addButton: some View {
        Menu {
            Button {
                showScanner = true
            } label: {
                Label(s.t("scan_title"), systemImage: "barcode.viewfinder")
            }
            Button {
                showTitleSearch = true
            } label: {
                Label(s.t("search_by_title_title"), systemImage: "magnifyingglass")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .frame(width: 54, height: 54)
                .background(Circle().fill(Color.appAccent).shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3))
                .foregroundColor(.white)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }


    private func searchAndEdit(_ isbn: String) async {
        currentSource = ""
        let book = await store.searchBookByIsbn(isbn, sources: enabledSources(), onSourceStart: { source in
            DispatchQueue.main.async { currentSource = source.displayName }
        })
        if let book {
            editTarget = EditTarget(book: book)
        } else {
            let normalized = ISBNService.normalizeIsbn(isbn)
            if ISBNService.isValidIsbn(normalized) {
                editTarget = EditTarget(book: Book(isbn: normalized, title: "", author: "", publisher: "",
                                                   purchasePrice: 0, purchaseDate: Date()))
            }
        }
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
            Color.black.opacity(0.25)
            VStack(spacing: 12) {
                ProgressView().tint(.white)
                Text(s.t("searching_title")).font(.subheadline).bold().foregroundColor(.white)
                if !currentSource.isEmpty {
                    Text(s.sourceLabel(currentSource)).font(.caption).foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground).opacity(0.95)))
            .shadow(radius: 10)
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
        HStack(spacing: 14) {
            coverImage
                .frame(width: 56, height: 80)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title.isEmpty ? s.t("unknown_title") : book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.author.isEmpty ? s.t("unknown_author") : book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    statusBadge

                    if let score = book.lexileScore {
                        HStack(spacing: 2) {
                            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 10))
                            Text(s.lexileLabel(score)).font(.caption2).fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.12)))
                    }
                }

                if book.status == "reading", let p = book.progress {
                    HStack(spacing: 8) {
                        ProgressView(value: p, total: 100)
                            .tint(.appReading)
                        Text("\(Int(p))%").font(.caption2).fontWeight(.medium).foregroundColor(.secondary)
                    }
                } else if book.status == "read", book.finishDate != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.appProfit)
                        Text(s.t("filter_read"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if let tags = book.tags, !tags.isEmpty {
                    Text(tags)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCardBg).shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1))
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
                    placeholderIcon
                }
            } else {
                AsyncImage(url: URL(string: url)) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else if phase.error != nil {
                        placeholderIcon
                    } else {
                        ProgressView().tint(.appAccent)
                    }
                }
            }
        } else {
            placeholderIcon
        }
    }

    private var placeholderIcon: some View {
        VStack {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }

    private var statusBadge: some View {
        let (color, label) = statusDetails
        return Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.15)))
            .foregroundColor(color)
    }

    private var statusDetails: (Color, String) {
        switch book.status {
        case "read":
            return (.appProfit, s.t("filter_read"))
        case "reading":
            return (.appReading, s.t("filter_reading"))
        case "wishlist":
            return (.appAccent, s.t("filter_wishlist"))
        default:
            return (Color(.systemGray), s.t("filter_unread"))
        }
    }
}


