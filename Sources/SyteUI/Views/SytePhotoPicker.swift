import PhotosUI
import SwiftUI

enum SytePhotoSource {
    case camera
    case library
}

/// The system camera or photo library, handing back one image or nil when cancelled.
struct SytePhotoPicker: UIViewControllerRepresentable {

    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    let source: SytePhotoSource
    let onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        switch source {
        case .camera:
            let camera = UIImagePickerController()
            camera.sourceType = .camera
            camera.delegate = context.coordinator
            return camera
        case .library:
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            let library = PHPickerViewController(configuration: configuration)
            library.delegate = context.coordinator
            return library
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {

        let onPick: (UIImage?) -> Void

        init(onPick: @escaping (UIImage?) -> Void) {
            self.onPick = onPick
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onPick(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onPick(nil)
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                return onPick(nil)
            }
            let onPick = onPick
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                let image = object as? UIImage
                DispatchQueue.main.async { onPick(image) }
            }
        }

    }

}
