import SwiftUI
import AVFoundation

/// 條碼偵測委派（由 ScannerView 持有）。
final class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcode: ((String) -> Void)?

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        for obj in metadataObjects {
            if let code = obj as? AVMetadataMachineReadableCodeObject,
               let value = code.stringValue, !value.isEmpty {
                onBarcode?(value)
                break
            }
        }
    }
}

/// 相機預覽層。
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        context.coordinator.previewLayer = layer
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = view.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func dismantleUIView(_ view: UIView, coordinator: Coordinator) {
        coordinator.previewLayer?.removeFromSuperlayer()
    }

    final class Coordinator {
        weak var previewLayer: AVCaptureVideoPreviewLayer?
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

    private var s: Strings { locale.strings }

    var body: some View {
        ZStack {
            CameraPreview(session: session)
                .ignoresSafeArea()

            VStack {
                HStack(spacing: 6) {
                    Image(systemName: "camera").foregroundColor(.white)
                    Text(cameraStatusText.isEmpty ? "..." : cameraStatusText)
                        .font(.caption2).foregroundColor(.white)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
                .padding(.top, 8)
                Spacer()
            }

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
        .onAppear {
            coordinator.onBarcode = { value in handleBarcode(value) }
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
        Task {
            await searchAndEdit(isbn)
            isSearching = false
        }
    }

    private func searchAndEdit(_ isbn: String) async {
        let book = await store.searchBookByIsbn(isbn, sources: enabledSources())
        if let book {
            editTarget = EditTarget(book: book)
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
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            cameraStatusText = "input_failed"
            return
        }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.metadataObjectTypes = [.ean13, .ean8, .upce]
            output.setMetadataObjectsDelegate(coordinator, queue: .main)
        }
        session.startRunning()
        cameraStatusText = session.isRunning ? "running" : "start_failed"
    }

    private func stopSession() {
        session.stopRunning()
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
