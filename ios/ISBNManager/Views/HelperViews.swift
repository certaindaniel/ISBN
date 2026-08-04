import SwiftUI
import UIKit

/// 日期選擇 sheet。
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let maxDate: Date
    var onPick: (Date) -> Void
    @State private var selection: Date

    init(initial: Date, maxDate: Date, onPick: @escaping (Date) -> Void) {
        self.maxDate = maxDate
        self.onPick = onPick
        _selection = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            DatePicker("", selection: $selection, in: Date.distantPast...maxDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("OK") { onPick(selection); dismiss() }
                    }
                }
        }
    }
}

/// 相機拍照 sheet（UIImagePickerController 包裝）。
struct ImagePickerSheet: UIViewControllerRepresentable {
    var onPick: (Data) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerSheet
        init(_ parent: ImagePickerSheet) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage,
               let data = img.jpegData(compressionQuality: 0.85) {
                parent.onPick(data)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
