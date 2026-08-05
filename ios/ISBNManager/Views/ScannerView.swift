import SwiftUI
import AVFoundation

/// 條碼偵測委派（由 ScannerView 持有）。偵測回呼在專用佇列，再跳回主執行緒更新 UI。
final class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcode: ((String) -> Void)?

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        for obj in metadataObjects {
            if let code = obj as? AVMetadataMachineReadableCodeObject,
               let value = code.stringValue, !value.isEmpty {
                AppLogger.debug("detected barcode: \(value)")
                DispatchQueue.main.async { self.onBarcode?(value) }
                break
            }
        }
    }
}

/// 相機預覽層。
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        PreviewView(session: session)
    }

    func updateUIView(_ view: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    func dismantleUIView(_ view: UIView, coordinator: Coordinator) {
        (view as? PreviewView)?.tearDown()
    }

    final class Coordinator {}

    /// 自訂 UIView：預覽 layer frame 隨 bounds 自動同步，避免 SwiftUI
    /// 初次 layout 時 bounds 為 0 導致預覽畫面不顯示。
    final class PreviewView: UIView {
        private var previewLayer: AVCaptureVideoPreviewLayer?

        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            backgroundColor = .black
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer
            self.layer.addSublayer(layer)
            layer.frame = bounds
        }

        required init?(coder: NSCoder) { fatalError("not supported") }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }

        func tearDown() {
            previewLayer?.removeFromSuperlayer()
            previewLayer = nil
        }
    }
}

/// 掃描 ISBN 畫面。
struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: BookStore
    @ObservedObject private var locale = LocaleManager.shared
    @State private var coordinator = ScannerCoordinator()
    @State private var session = AVCaptureSession()
    @State private var manualIsbn = ""
    @State private var isSearching = false
    @State private var editTarget: EditTarget?
    @State private var torchOn = false
    @State private var toast: String?
    @State private var showSettings = false
    @State private var cameraDenied = false
    @State private var cameraStatusText = ""

    // 偵測診斷（debug 用）
    @State private var detectedCount = 0
    @State private var lastDetected = ""
    @State private var diagDetail = ""
    @State private var currentSource = ""
    @State private var showTitleSearch = false

    /// 相機 session 與條碼偵測共用專用佇列：避免 startRunning 阻塞主執行緒，
    /// 也避免 metadata delegate 綁在 .main 導致偵測不觸發。
    private let scanQueue = DispatchQueue(label: "com.daniel.isbn.scanner", qos: .userInitiated)

    private var s: Strings { locale.strings }

    var body: some View {
        ZStack {
            CameraPreview(session: session)
                .ignoresSafeArea()

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "camera").foregroundColor(.white)
                    Text(cameraStatusText.isEmpty ? "..." : cameraStatusText)
                        .font(.caption2).foregroundColor(.white)
                }
                if !diagDetail.isEmpty {
                    Text(diagDetail).font(.system(size: 9)).foregroundColor(.white)
                }
                if detectedCount > 0 {
                    Text("detected \(detectedCount): \(lastDetected)")
                        .font(.system(size: 9)).foregroundColor(.green)
                }
                Spacer()
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
            .padding(.top, 8)

            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 3)
                .frame(width: 280, height: 280)

            VStack {
                Spacer()
                bottomPanel
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .background(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))

            if let toast {
                VStack {
                    Spacer()
                    Text(toast).font(.subheadline).foregroundColor(.white)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.8)))
                        .padding(.bottom, 150)
                }
            }

            if cameraDenied {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill").font(.system(size: 40)).foregroundColor(.gray)
                    Text(s.t("camera_denied")).multilineTextAlignment(.center)
                        .font(.subheadline)
                    Button(s.t("camera_open_settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                .padding(20)
            }

            if isSearching {
                VStack {
                    Spacer()
                    VStack(spacing: 4) {
                        ProgressView().tint(.white)
                        Text(s.t("searching_title"))
                            .font(.subheadline).foregroundColor(.white)
                        if !currentSource.isEmpty {
                            Text(s.sourceLabel(currentSource))
                                .font(.caption2).foregroundColor(.white)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.7)))
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarTitle(s.t("scan_title"), displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
                .accessibilityLabel(s.t("settings_title"))
            }
        }
        .navigationDestination(isPresented: $showSettings) { SettingsView() }
        .sheet(item: $editTarget) { target in
            BookEditView(initialBook: target.book, onSaved: { dismiss() })
        }
        .sheet(isPresented: $showTitleSearch) {
            TitleSearchSheet(
                onSelect: { book in editTarget = EditTarget(book: book) },
                onManualIsbn: { isbn in Task { await searchAndEdit(isbn) } }
            )
        }
        .onAppear {
            coordinator.onBarcode = { value in
                detectedCount += 1
                lastDetected = value
                handleBarcode(value)
            }
            startSession()
        }
        .onDisappear { stopSession() }
    }

    // MARK: - 底部控制區

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            Text(s.t("scan_area_hint"))
                .font(.subheadline).foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.5)))

            HStack {
                TextField(s.t("manual_isbn_hint"), text: $manualIsbn)
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .padding(.vertical, 10).padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.5)))
                Button(s.t("search_button")) { searchManual() }
                    .buttonStyle(.borderedProminent)
            }

            Button { toggleTorch() } label: {
                Image(systemName: torchOn ? "flashlight.fill" : "flashlight")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(s.t("torch"))
        }
    }

    // MARK: - 動作

    private func handleBarcode(_ value: String) {
        guard !isSearching else { return }
        isSearching = true
        currentSource = ""
        Task {
            await searchAndEdit(value)
            isSearching = false
        }
    }

    private func searchManual() {
        let isbn = manualIsbn.trimmingCharacters(in: .whitespaces)
        guard !isbn.isEmpty else {
            presentMessage(s.t("please_enter_isbn"))
            return
        }
        guard !isSearching else { return }
        isSearching = true
        currentSource = ""
        Task {
            await searchAndEdit(isbn)
            isSearching = false
        }
    }

    private func searchAndEdit(_ isbn: String) async {
        // 硬上限：避免某個查詢來源伺服器卡住（不回應/慢速串流），
        // 讓掃描器看起來「死機」。20 秒沒結果就放行、可再掃。
        let deadlineTask = Task { @MainActor [self] in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            if !Task.isCancelled {
                presentMessage(s.t("search_timeout"))
                isSearching = false
            }
        }
        let book = await store.searchBookByIsbn(isbn, sources: enabledSources(), onSourceStart: { source in
            DispatchQueue.main.async { currentSource = source.displayName }
        })
        deadlineTask.cancel()
        if let book {
            editTarget = EditTarget(book: book)
        } else if store.errorCode == "scan_not_isbn_ean" {
            // B2: 掃到非 ISBN 的 EAN → 提示後自動轉書名搜尋
            presentMessage(store.localizedError(s))
            store.clearError()
            showTitleSearch = true
        } else {
            presentMessage(store.errorCode != nil ? store.localizedError(s) : (store.error ?? s.t("cannot_find_book")))
            store.clearError()
        }
    }

    private func enabledSources() -> [ApiSource] {
        let defaults = UserDefaults.standard
        let stored = defaults.stringArray(forKey: "enabled_api_sources") ?? []
        if stored.isEmpty { return ApiSource.defaultEnabled() }
        return ApiSource.allCases.filter { stored.contains($0.rawValue) }
    }

    private func presentMessage(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
    }

    // MARK: - 相機

    private func startSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraStatusText = "auth:authorized"
            configureAndStart()
        case .notDetermined:
            cameraStatusText = "auth:notDetermined"
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        cameraStatusText = "auth:granted"
                        configureAndStart()
                    } else {
                        cameraStatusText = "auth:denied"
                        cameraDenied = true
                    }
                }
            }
        default:
            cameraStatusText = "auth:denied"
            cameraDenied = true
        }
    }

    private func configureAndStart() {
        cameraStatusText = "starting"
        scanQueue.async {
            session.sessionPreset = .high
            var inOk = false, outOk = false, typesOk = false, connOk = false
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                DispatchQueue.main.async {
                    cameraStatusText = "input_failed"
                    diagDetail = "no device or input"
                }
                return
            }
            session.addInput(input)
            inOk = true
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.metadataObjectTypes = [.ean13, .ean8, .upce]
                output.setMetadataObjectsDelegate(coordinator, queue: scanQueue)
                outOk = true
                typesOk = true
            }
            session.startRunning()
            let running = session.isRunning
            connOk = output.connections.first?.isEnabled ?? false
            AppLogger.debug("camera in:\(inOk ? 1 : 0) out:\(outOk ? 1 : 0) types:\(typesOk ? 1 : 0) conn:\(connOk ? 1 : 0) running:\(running ? 1 : 0)")
            DispatchQueue.main.async {
                cameraStatusText = running ? "running" : "start_failed"
                diagDetail = "in:\(inOk ? 1 : 0) out:\(outOk ? 1 : 0) types:\(typesOk ? 1 : 0) conn:\(connOk ? 1 : 0)"
            }
        }
    }

    private func stopSession() {
        scanQueue.async { session.stopRunning() }
    }

    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = torchOn ? .off : .on
            torchOn.toggle()
            device.unlockForConfiguration()
        } catch {}
    }
}
