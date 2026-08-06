import SwiftUI
import PhotosUI
import UIKit

/// 書籍新增/編輯畫面。
struct BookEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: BookStore
    @ObservedObject private var locale = LocaleManager.shared
    let initialBook: Book?
    var onSaved: (() -> Void)? = nil

    @State private var isbn = ""
    @State private var title = ""
    @State private var author = ""
    @State private var publisher = ""
    @State private var description = ""
    @State private var purchasePriceText = ""
    @State private var salePriceText = ""
    @State private var lexileText = ""
    @State private var purchaseDate = Date()
    @State private var saleDate: Date?
    @State private var startDate: Date?
    @State private var finishDate: Date?
    @State private var progressText = ""
    @State private var language: String?
    @State private var readStatus = "unread"
    @State private var tags = ""
    @State private var coverImageData: Data?
    @State private var showImagePicker = false
    @State private var showLexile = false
    @State private var toast: String?
    @State private var formError: String?
    @State private var showUnsavedConfirm = false

    private var s: Strings { locale.strings }
    private var isNew: Bool { initialBook == nil }

    private var calculatedProfit: (profit: Double, isProfit: Bool)? {
        guard let purchase = Double(purchasePriceText), let sale = Double(salePriceText) else { return nil }
        return (sale - purchase, (sale - purchase) >= 0)
    }

    private var similarBooks: [Book]? {
        guard let book = initialBook else { return nil }
        let list = Database.shared.similarBooks(to: book, limit: 5)
        return list.isEmpty ? nil : list
    }

    var body: some View {
        NavigationStack {
            Form {
                if let formError {
                    Section {
                        Text(formError)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    coverHeader
                    TextField(s.t("manual_isbn_label"), text: $isbn)
                        .keyboardType(.numberPad)
                        .disabled(!isNew)

                    if isNew && !isbn.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button(s.t("fill_from_isbn")) {
                            Task { await fetchFromIsbn() }
                        }
                    }

                    TextField(s.t("label_title_required"), text: $title)
                    TextField(s.t("label_author_required"), text: $author)
                    TextField(s.t("label_publisher_required"), text: $publisher)
                    TextField(s.t("label_description"), text: $description, axis: .vertical)
                        .lineLimit(2...5)

                    if let language {
                        HStack {
                            Image(systemName: "globe").foregroundColor(.appAccent)
                            Text(s.languageLabel(languageName(language)))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Picker("", selection: $readStatus) {
                        Text(s.t("filter_unread")).tag("unread")
                        Text(s.t("filter_reading")).tag("reading")
                        Text(s.t("filter_read")).tag("read")
                        Text(s.t("filter_wishlist")).tag("wishlist")
                    }
                    .pickerStyle(.segmented)

                    if readStatus == "reading" {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(s.t("progress_percent")).foregroundColor(.secondary)
                                Spacer()
                                Text("\(progressText.isEmpty ? "0" : progressText)%").bold()
                            }
                            Slider(value: Binding(
                                get: { Double(progressText) ?? 0 },
                                set: { progressText = String(Int($0)) }
                            ), in: 0...100, step: 1)
                            .tint(.appReading)
                        }
                        .padding(.vertical, 4)
                    }

                    HStack {
                        Text(s.t("progress_start"))
                        Spacer()
                        Text(startDate.map(dateString) ?? s.t("progress_none"))
                            .foregroundColor(startDate != nil ? .primary : .secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { pickDate(.start) }

                    HStack {
                        Text(s.t("progress_finish"))
                        Spacer()
                        Text(finishDate.map(dateString) ?? s.t("progress_none"))
                            .foregroundColor(finishDate != nil ? .primary : .secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { pickDate(.finish) }

                    TextField(s.t("tags_hint"), text: $tags)
                } header: {
                    Text(s.t("progress_title"))
                }

                Section {
                    HStack {
                        TextField(s.t("example_lexile_hint"), text: $lexileText)
                            .keyboardType(.numberPad)
                        Button {
                            showLexile = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.appAccent)
                        }
                        .buttonStyle(.plain)
                    }
                    if language == "en" {
                        Text(s.t("lexile_manual_title")).font(.caption).foregroundColor(.appAccent)
                    }
                } header: {
                    Text(s.t("label_lexile"))
                }

                Section {
                    TextField(s.t("label_purchase_price_required"), text: $purchasePriceText)
                        .keyboardType(.decimalPad)

                    HStack {
                        Text(s.t("purchase_date_title"))
                        Spacer()
                        Text(dateString(purchaseDate)).foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { pickDate(.purchase) }

                    TextField(s.t("label_sale_price"), text: $salePriceText)
                        .keyboardType(.decimalPad)

                    if let saleDate {
                        HStack {
                            Text(s.t("sale_date_title"))
                            Spacer()
                            Text(dateString(saleDate)).foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { pickDate(.sale) }
                    } else {
                        Button(s.t("set_sale_date_label")) { pickDate(.sale) }
                    }

                    if let profitInfo = calculatedProfit {
                        HStack {
                            Text(s.t("profit_label")).bold()
                            Spacer()
                            Text(String(format: "%.2f", profitInfo.profit))
                                .bold()
                                .foregroundColor(profitInfo.profit >= 0 ? .appProfit : .appLoss)
                        }
                    }
                } header: {
                    Text(s.t("finance_title"))
                }

                if let similar = similarBooks {
                    Section {
                        ForEach(similar) { b in
                            Text("• \(b.title.isEmpty ? s.t("unknown_title") : b.title)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text(s.t("similar_title"))
                    }
                }
            }
            .navigationTitle(isNew ? s.t("new_book") : s.t("edit_book"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(s.t("cancel")) { confirmDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(s.t("save_book_button")) { save() }
                        .bold()
                }
            }
        }
        .onAppear { populate() }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerSheet { data in
                coverImageData = data
                toast = s.t("photo_taken")
            }
        }
        .sheet(isPresented: $showLexile) {
            LexileWebView(query: lexileQuery()) { value in
                lexileText = String(value)
                toast = s.lexileRefilled(value)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(initial: datePickerInitial(), maxDate: Date()) { picked in
                switch datePickerKind {
                case .purchase: purchaseDate = picked
                case .sale: saleDate = picked
                case .start: startDate = picked
                case .finish: finishDate = picked
                }
                showDatePicker = false
            }
        }
        .sheet(isPresented: $paywallPresented) {
            PaywallView()
        }
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.footnote)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .foregroundColor(.white)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(s.t("unsavedChangesTitle"), isPresented: $showUnsavedConfirm) {
            Button(s.t("saveAndLeave")) { save() }
            Button(s.t("discard"), role: .destructive) { dismiss() }
            Button(s.t("cancel"), role: .cancel) {}
        } message: {
            Text(s.t("unsavedChangesContent"))
        }
    }

    // MARK: - 封面

    private var coverHeader: some View {
        HStack {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                if let data = coverImageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill().frame(width: 110, height: 165).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.15), radius: 4)
                } else if let url = initialBook?.coverUrl {
                    remoteCover(url)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.appAccent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .frame(width: 110, height: 165)
                        .overlay(VStack(spacing: 8) {
                            Image(systemName: "camera.fill").font(.system(size: 32)).foregroundColor(.appAccent)
                            Text(s.t("take_photo")).font(.caption).fontWeight(.medium).foregroundColor(.appAccent)
                        })
                        .onTapGesture { showImagePicker = true }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(s.t("take_photo"))
                }
                if coverImageData != nil || initialBook?.coverUrl != nil {
                    Button { showImagePicker = true } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.appAccent).shadow(radius: 2))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel(s.t("take_photo"))
                    .offset(x: 4, y: 4)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }


    @ViewBuilder private func remoteCover(_ url: String) -> some View {
        if url.hasPrefix("/") || url.hasPrefix("file://") {
            let path = url.replacingOccurrences(of: "file://", with: "")
            if let ui = UIImage(contentsOfFile: path) {
                Image(uiImage: ui).resizable().scaledToFill().frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(radius: 4)
            } else {
                placeholderCover
            }
        } else {
            AsyncImage(url: URL(string: url)) { phase in
                if let img = phase.image {
                    img.resizable().scaledToFill().frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(radius: 4)
                } else { placeholderCover }
            }
        }
    }

    private var placeholderCover: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray4)).frame(width: 120, height: 180).overlay(Image(systemName: "book").foregroundColor(.secondary))
    }

    // MARK: - 動作

    private func populate() {
        guard let book = initialBook else { return }
        isbn = book.isbn
        title = book.title
        author = book.author
        publisher = book.publisher
        description = book.description ?? ""
        purchasePriceText = String(format: "%.2f", book.purchasePrice)
        if let sale = book.salePrice { salePriceText = String(format: "%.2f", sale) }
        startDate = book.startDate
        finishDate = book.finishDate
        if let p = book.progress { progressText = String(Int(p)) }
        if let lexile = book.lexileScore { lexileText = String(lexile) }
        purchaseDate = book.purchaseDate
        saleDate = book.saleDate
        tags = book.tags ?? ""
        language = book.language
        readStatus = book.status
    }

    private func hasUnsavedChanges() -> Bool {
        if isNew {
            return !title.isEmpty || !author.isEmpty || !publisher.isEmpty || !isbn.isEmpty ||
                   !purchasePriceText.isEmpty || coverImageData != nil
        }
        guard let book = initialBook else { return false }
        if title.trimmingCharacters(in: .whitespaces) != book.title { return true }
        if author.trimmingCharacters(in: .whitespaces) != book.author { return true }
        if publisher.trimmingCharacters(in: .whitespaces) != book.publisher { return true }
        if description.trimmingCharacters(in: .whitespaces) != (book.description ?? "") { return true }
        if isbn.trimmingCharacters(in: .whitespaces) != book.isbn { return true }
        if purchasePriceText.trimmingCharacters(in: .whitespaces) != String(format: "%.2f", book.purchasePrice) { return true }
        if salePriceText.trimmingCharacters(in: .whitespaces) != (book.salePrice.map { String(format: "%.2f", $0) } ?? "") { return true }
        if lexileText.trimmingCharacters(in: .whitespaces) != (book.lexileScore.map(String.init) ?? "") { return true }
        if purchaseDate != book.purchaseDate { return true }
        if saleDate != book.saleDate { return true }
        if startDate != book.startDate { return true }
        if finishDate != book.finishDate { return true }
        if progressText.trimmingCharacters(in: .whitespaces) != (book.progress.map { String(Int($0)) } ?? "") { return true }
        if tags.trimmingCharacters(in: .whitespaces) != (book.tags ?? "") { return true }
        if readStatus != book.status { return true }
        if language != book.language { return true }
        return false
    }

    private func fetchFromIsbn() async {
        let normalized = ISBNService.normalizeIsbn(isbn)
        guard ISBNService.isValidIsbn(normalized) else {
            toast = s.t("manual_isbn_hint")
            return
        }
        guard let book = await store.searchBookByIsbn(normalized, sources: []) else {
            toast = s.t("cannot_find_book")
            return
        }
        title = book.title
        author = book.author
        publisher = book.publisher
        description = book.description ?? ""
        language = book.language
        if let cover = book.coverUrl, let url = URL(string: cover),
           let data = (try? await URLSession.shared.data(from: url))?.0 {
            coverImageData = data
        }
    }

    private func save() {
        formError = nil
        guard !title.isEmpty, !author.isEmpty, !publisher.isEmpty, !isbn.isEmpty, !purchasePriceText.isEmpty else {
            let msg = s.t("pleaseFillRequiredFields")
            formError = msg
            toast = msg
            return
        }
        let coverURL = coverImageData != nil ? saveCoverImage() : initialBook?.coverUrl
        let book = Book(id: initialBook?.id, isbn: isbn.trimmingCharacters(in: .whitespaces),
                        title: title.trimmingCharacters(in: .whitespaces),
                        author: author.trimmingCharacters(in: .whitespaces),
                        publisher: publisher.trimmingCharacters(in: .whitespaces),
                        coverUrl: coverURL,
                        description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
                        purchasePrice: Double(purchasePriceText) ?? 0,
                        salePrice: salePriceText.isEmpty ? nil : Double(salePriceText),
                        purchaseDate: purchaseDate, saleDate: saleDate,
                        startDate: startDate, finishDate: finishDate,
                        progress: progressText.isEmpty ? nil : Double(progressText),
                        quantity: initialBook?.quantity ?? 1, status: readStatus,
                        language: language, lexileScore: lexileText.isEmpty ? nil : Int(lexileText),
                        tags: tags.isEmpty ? nil : tags.trimmingCharacters(in: .whitespaces))
        Task {
            let ok = isNew ? await store.addBook(book) : await store.updateBook(book)
            if ok {
                toast = s.t("book_saved")
                if let onSaved { onSaved() }
                dismiss()
            } else if store.errorCode == "free_limit_reached" {
                presentPaywall()
            } else {
                toast = store.errorCode != nil ? store.localizedError(s) : (store.error ?? s.t("save_failed"))
                store.clearError()
            }
        }
    }

    private func saveCoverImage() -> String? {
        guard let data = coverImageData else { return nil }
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let filename = "cover_\(Int(Date().timeIntervalSince1970)).jpg"
        let path = (dir as NSString).appendingPathComponent(filename)
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return path
        } catch {
            return nil
        }
    }

    private func pickDate(_ kind: DateKind) {
        datePickerKind = kind
        showDatePicker = true
    }

    private func datePickerInitial() -> Date {
        switch datePickerKind {
        case .purchase: return purchaseDate
        case .sale: return saleDate ?? Date()
        case .start: return startDate ?? Date()
        case .finish: return finishDate ?? Date()
        }
    }

    enum DateKind { case purchase, sale, start, finish }

    @State private var showDatePicker = false
    @State private var datePickerKind: DateKind = .purchase

    private func confirmDismiss() {
        if hasUnsavedChanges() {
            showUnsavedConfirm = true
        } else {
            dismiss()
        }
    }

    private func lexileQuery() -> String {
        let isbnTrim = isbn.trimmingCharacters(in: .whitespaces)
        if !isbnTrim.isEmpty { return isbnTrim }
        return "\(title) \(author)".trimmingCharacters(in: .whitespaces)
    }

    private func presentPaywall() {
        paywallPresented = true
    }

    @State private var paywallPresented = false

    private func dateString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    private func languageName(_ code: String) -> String {
        switch code {
        case "en": return "English (英文)"
        case "zh": return "Chinese (中文)"
        case "ja": return "Japanese (日文)"
        default: return code
        }
    }
}
