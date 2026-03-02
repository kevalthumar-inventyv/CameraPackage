//
//  CameraExportFunctions.swift
//  CameraLib
//
//  Created by Keval Thumar on 27/02/26.
//

import Foundation


public enum CameraStatus: Int32 {
    case success = 0
    case permissionDenied = 1
    case unavailable = 2
    case cancelled = 3
    case conversionFailed = 4
    case noTopViewController = 5
}

public typealias CameraCallback = @Sendable @convention(c) (
    Int32,
    UnsafePointer<CChar>?
) -> Void


#if canImport(UIKit)
@_cdecl("open_camera")
public func open_camera(_ callback: @escaping CameraCallback) {
    DispatchQueue.main.async {
        print("[\(HelperMethods.shared.getCurrentTimeStamp())] Open Camera called from wrapper")
        CameraLibrary.shared.openCamera { result in
            switch result {
            case .success(let data):
                // Convert Swift String to a null-terminated UTF-8 C string buffer.
                let utf8CString = Array((data as String).utf8CString) // includes trailing `\0`
                let byteCount = utf8CString.count
                let rawBuf = UnsafeMutablePointer<CChar>.allocate(capacity: byteCount)
                rawBuf.initialize(from: utf8CString, count: byteCount)
                MainActor.assumeIsolated { callback(CameraStatus.success.rawValue, UnsafePointer(rawBuf)) }
    
            case .failure(let status):
                MainActor.assumeIsolated { callback(getErrorStatus(status), nil) }
            }
        }
    }
}

#endif

@_cdecl("swift_free")
public func swift_free(_ ptr: UnsafeMutableRawPointer?) {
    free(ptr)
}

@_cdecl("add_number")
public func add_number() {
    print("Hello from Swift! This is a test function to verify the C callback mechanism.")
}

public func getErrorStatus(_ status: WCameraError) -> Int32 {
    switch status {
    case .permissionDenied:
        return CameraStatus.permissionDenied.rawValue
    case .cameraUnavailable:
        return CameraStatus.unavailable.rawValue
    case .noTopViewController:
        return CameraStatus.noTopViewController.rawValue
    case .imageConversionFailed:
        return CameraStatus.conversionFailed.rawValue
    case .cancelled:
        return CameraStatus.cancelled.rawValue
    }
}

