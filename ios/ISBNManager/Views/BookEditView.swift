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
    @State private var showUnsavedConfirm = false

    private var s: Strings { locale.strings }
    private var isNew: Bool { initialBook == nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    coverSection

                    TextField(s.t("manual_isbn_label"), text: $isbn)
                        .keyboardType(.numberPad)
                        .disabled(!isNew)
                        .textFieldStyle(.roundedBorder)

                    TextField(s.t("label_title_required"), text: $title)
                        .textFieldStyle(.roundedBorder)
                    TextField(s.t("label_author_required"), text: $author)
                        .textFieldStyle(.roundedBorder)
                    TextField(s.t("label_publisher_required"), text: $publisher)
                        .textFieldStyle(.roundedBorder)
                    TextField(s.t("label_description"), text: $description)
                        .textFieldStyle(.roundedBorder)

                    if let language {
                        HStack {
                            Image(systemName: "globe")
                            Text(s.languageLabel(languageName(language)))
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray6)))
                    }

                    readStatusSection
                    progressSection
                    lexileSection
                    purchaseSection
                    saleSection
                    profitSection
                    similarSection
                    saveButton
                }
                .padding(16)
            }
            .navigationTitle(isNew ? s.t("new_book") : s.t("edit_book"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(s.t("save_book_button")) { save() }
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
                Text(toast).font(.footnote).padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.8)).foregroundColor(.white)).padding(.top, 8)
            }
        }
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(s.t("cancel")) { confirmDismiss() }
            }
        }
        .confirmationDialog(s.t("unsavedChangesTitle"), isPresented: $showUnsavedConfirm) {
            Button(s.t("saveAndLeave")) { save() }
            Button(s.t("discard"), role: .destructive) { dismiss() }
            Button(s.t("cancel"), role: .cancel) {}
        } message: {
            Text(s.t("unsavedChangesContent"))
        }
    }

    // MARK: - 封面

    private var coverSection: some View {
        HStack {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                if let data = coverImageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill().frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(radius: 4)
                } else if let url = initialBook?.coverUrl {
                    remoteCover(url)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 120, height: 180)
                        .overlay(VStack(spacing: 8) {
                            Image(systemName: "camera").font(.system(size: 40)).foregroundColor(.accentColor)
                            Text(s.t("take_photo")).font(.caption).foregroundColor(.accentColor)
                        })
                        .onTapGesture { showImagePicker = true }
                }
                if coverImageData != nil || initialBook?.coverUrl != nil {
                    Button { showImagePicker = true } label: {
                        Image(systemName: "camera").padding(6).background(Circle().fill(Color.accentColor)).foregroundColor(.white)
                    }
                    .offset(x: -8, y: -8)
                }
            }
            Spacer()
        }
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
        RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray4)).frame(width: 120, height: 180).overlay(Image(systemName: "book").foregroundColor(.gray))
    }

    // MARK: - 閱讀狀態

    private var readStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(readStatusLabel).font(.subheadline).bold()
            Picker("", selection: $readStatus) {
                Text(s.t("filter_unread")).tag("unread")
                Text(s.t("filter_reading")).tag("reading")
                Text(s.t("filter_read")).tag("read")
                Text(s.t("filter_wishlist")).tag("wishlist")
            }.pickerStyle(.segmented)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
    }

    // MARK: - 閱讀進度

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(s.t("progress_title")).font(.subheadline).bold()

            HStack {
                Text(s.t("progress_start"))
                Spacer()
                Text(startDate.map(dateString) ?? s.t("progress_none"))
                    .foregroundColor(startDate != nil ? .primary : .secondary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray6)))
            .onTapGesture { pickDate(.start) }

            HStack {
                Text(s.t("progress_finish"))
                Spacer()
                Text(finishDate.map(dateString) ?? s.t("progress_none"))
                    .foregroundColor(finishDate != nil ? .primary : .secondary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray6)))
            .onTapGesture { pickDate(.finish) }

            if readStatus == "reading" {
                HStack {
                    Text(s.t("progress_percent")).foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { Double(progressText) ?? 0 },
                        set: { progressText = String(Int($0)) }
                    ), in: 0...100, step: 1)
                    Text("\(progressText.isEmpty ? "0" : progressText)%").frame(width: 40)
                }
            }

            TextField(s.t("tags_hint"), text: $tags).textFieldStyle(.roundedBorder)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.08)))
    }

    private var readStatusLabel: String {
        switch readStatus {
        case "read": return s.t("filter_read")
        case "reading": return s.t("filter_reading")
        case "wishlist": return s.t("filter_wishlist")
        default: return s.t("filter_unread")
        }
    }

    // MARK: - Lexile

    private var lexileSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(s.t("label_lexile")).font(.caption).foregroundColor(.secondary)
            HStack {
                TextField(s.t("example_lexile_hint"), text: $lexileText).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                Button {
                    showLexile = true
                } label: { Image(systemName: "open.in.new") }
            }
            if language == "en" {
                Text(s.t("lexile_manual_title")).font(.caption).foregroundColor(.blue)
            } else {
                Text(s.t("lexile_manual_label")).font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 購買

    private var purchaseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(s.t("label_purchase_price_required"), text: $purchasePriceText)
                .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
            HStack {
                Text(s.t("purchase_date_title"))
                Spacer()
                Text(dateString(purchaseDate)).foregroundColor(.secondary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray6)))
            .onTapGesture { pickDate(.purchase) }
        }
    }

    private var saleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(s.t("label_sale_price"), text: $salePriceText)
                .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
            if let saleDate {
                HStack {
                    Text(s.t("sale_date_title"))
                    Spacer()
                    Text(dateString(saleDate)).foregroundColor(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray6)))
                .onTapGesture { pickDate(.sale) }
            } else {
                Button(s.t("set_sale_date_label")) { pickDate(.sale) }
            }
        }
    }

    private var profitSection: some View {
        let purchase = Double(purchasePriceText) ?? 0
        let sale = Double(salePriceText)
        if purchasePriceText.isEmpty || sale == nil { return AnyView(EmptyView()) }
        let profit = sale! - purchase
        let color = profit >= 0 ? Color.green : Color.red
        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Text(s.t("profit_calculation")).font(.headline)
                Text("\(s.t("label_purchase_price_required")): \(purchasePriceText)")
                Text("\(s.t("label_sale_price")): \(salePriceText)")
                Divider()
                HStack {
                    Text(s.t("profit_label")).bold()
                    Spacer()
                    Text(String(format: "%.2f", profit)).bold().foregroundColor(color)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
        )
    }

    // MARK: - 相似書籍推薦

    private var similarSection: some View {
        guard let book = initialBook else { return AnyView(EmptyView()) }
        let similar = Database.shared.similarBooks(to: book, limit: 5)
        if similar.isEmpty { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Text(s.t("similar_title")).font(.subheadline).bold()
                ForEach(similar) { b in
                    Text("• \(b.title.isEmpty ? s.t("unknown_title") : b.title)")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.indigo.opacity(0.08)))
        )
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(s.t("save_book_button"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
                .foregroundColor(.white)
        }
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

    private func save() {
        guard !title.isEmpty, !author.isEmpty, !publisher.isEmpty, !isbn.isEmpty, !purchasePriceText.isEmpty else {
            toast = s.t("pleaseFillRequiredFields")
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
