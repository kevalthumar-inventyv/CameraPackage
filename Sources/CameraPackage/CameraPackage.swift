// The Swift Programming Language
// https://docs.swift.org/swift-book

import AVFoundation

public enum WCameraError: Error {
    case permissionDenied
    case cameraUnavailable
    case noTopViewController
    case imageConversionFailed
    case cancelled
}

@MainActor
final class CameraLibrary: NSObject {
    
    static let shared = CameraLibrary()
    private override init() {}
    
    private var callback: (@MainActor (Result<String, WCameraError>) -> Void)?
    
}

#if canImport(UIKit)
import UIKit
// MARK: - Delegate
extension CameraLibrary: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Public Entry Point
    func openCamera(callback: @MainActor @escaping (Result<String, WCameraError>) -> Void) {
        self.callback = callback
        print("[\(HelperMethods.shared.getCurrentTimeStamp())] Checking camera permission")
        checkPermissionAndProceed()
    }
    
    // MARK: - Permission Handling
    private func checkPermissionAndProceed() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] Permission already granted.")
            presentCamera()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    print("[\(HelperMethods.shared.getCurrentTimeStamp())] Permission denied by user.")
                    Task { @MainActor in
                        self.callback?(.failure(.permissionDenied))
                    }
                    return
                }
                print("[\(HelperMethods.shared.getCurrentTimeStamp())] Permission granted by user.")
                Task { @MainActor in
                    self.presentWhenAppIsActive()
                }
            }
            
        case .denied, .restricted:
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] Permission denied or restricted.")
            callback?(.failure(.permissionDenied))
            
        @unknown default:
            callback?(.failure(.permissionDenied))
        }
    }
    
    private func presentWhenAppIsActive() {
        if UIApplication.shared.applicationState == .active {
            self.presentCamera()
            return
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            self.presentCamera()
        }
    }
    
    
    // MARK: - Present Camera
    private func presentCamera() {
        print("[\(HelperMethods.shared.getCurrentTimeStamp())] Start to get currentTopViewController")
        guard let topVC = currentTopViewController() else {
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] Failed to find top view controller.")
            callback?(.failure(.noTopViewController))
            return
        }
        print("[\(HelperMethods.shared.getCurrentTimeStamp())] Found top view controller")
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] Camera source type is not available.")
            callback?(.failure(.cameraUnavailable))
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        imagePicker.cameraDevice = .rear
        //        imagePicker.modalPresentationStyle = .fullScreen Default is .automatic which is .fullScreen on iPhone and .pageSheet on iPad same as HFY.
        
        topVC.present(imagePicker, animated: true)
    }
    
    // MARK: - Top VC Resolver
    private func currentTopViewController() -> UIViewController? {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = windowScene.windows
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        else {
            return nil
        }
        
        return resolveTop(from: root)
    }
    
    private func resolveTop(from vc: UIViewController) -> UIViewController {
        
        if let presented = vc.presentedViewController {
            return resolveTop(from: presented)
        }
        
        if let nav = vc as? UINavigationController,
           let visible = nav.visibleViewController {
            return resolveTop(from: visible)
        }
        
        if let tab = vc as? UITabBarController,
           let selected = tab.selectedViewController {
            return resolveTop(from: selected)
        }
        
        return vc
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)
        
        let image = info[.editedImage] as? UIImage
        
        if let image = image {
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] Start converting image to JPEG data")
            let data = image.jpegData(compressionQuality: 1)
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] End converting image to JPEG data")
            
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] Start converting image to Base64")
            let base64String = data?.base64EncodedString() ?? ""
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] End converting image to Base64, invoking callback")
            callback?(.success(base64String))
            
        } else {
            print("[\(HelperMethods.shared.getCurrentTimeStamp())] Failed to convert image to JPEG data.")
            callback?(.failure(.imageConversionFailed))
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        print("[\(HelperMethods.shared.getCurrentTimeStamp())] User cancelled image picking.")
        callback?(.failure(.cancelled))
    }
}
#endif

