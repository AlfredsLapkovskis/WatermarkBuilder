//
//  ViewModel.swift
//  WatermarkBuilder
//
//  Created by Alfred Lapkovsky on 21/05/2022.
//


import Foundation
import SwiftUI
import UIKit
import PhotosUI


class ViewModel : NSObject, ObservableObject {
    
    @Published var controlsType         : ControlsType                         = .textWatermark
    @Published var watermarkTextParams  : ImageProcessor.TextWatermarkParams   = ViewModel.createDefaultWatermarkTextParams  ()
    @Published var watermarkCustomParams: ImageProcessor.CustomWatermarkParams = ViewModel.createDefaultCustomWatermarkParams()
    @Published var requestStatus        : RequestStatus                        = .idle
    @Published var imageData            : ImageProcessor.ImageData?
    
    private weak var imagePicker         : UIViewController?
    private weak var watermarkImagePicker: UIViewController?
    
    private var requestCounter = 0
    
    static let supportedFontFamilies = [
        "Roboto",
        "Times New Roman"
    ]
    
    static let defaultFontSize = 12
    static let fontSizes       = [
        8,
        12,
        16,
        18,
        24,
        32,
        36,
        48,
        64,
        72
    ]
    
    func takePicture(_ watermark: Bool = false) {
        let imagePickerViewController           = UIImagePickerController()
        imagePickerViewController.sourceType    = .camera
        imagePickerViewController.allowsEditing = true
        imagePickerViewController.delegate      = self
        
        if watermark {
            watermarkImagePicker = imagePickerViewController
        } else {
            imagePicker = imagePickerViewController
        }
        
        getTopViewController()?.present(imagePickerViewController, animated: true)
    }
    
    func importPicture(_ watermark: Bool = false) {
        var configuration            = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter         = .images
        
        let imagePickerViewController      = PHPickerViewController(configuration: configuration)
        imagePickerViewController.delegate = self
        
        if watermark {
            watermarkImagePicker = imagePickerViewController
        } else {
            imagePicker = imagePickerViewController
        }
        
        getTopViewController()?.present(imagePickerViewController, animated: true)
    }
    
    func processImage() {
        guard let imageData = imageData else { return }

        requestStatus   = .pending
        requestCounter += 1
        
        let counter = requestCounter
        
        Task { @MainActor in
            do {
                let imageData = controlsType == .textWatermark
                    ? try await ImageProcessor.shared.processImage(imageData, params: watermarkTextParams)
                    : try await ImageProcessor.shared.processImage(imageData, params: watermarkCustomParams)
                
                guard case .pending = requestStatus, counter == requestCounter else {
                    return
                }
                
                requestStatus = .success(data: imageData)
                
            } catch {
                assert(error is ImageProcessor.Error)
                
                guard case .pending = requestStatus, counter == requestCounter else {
                    return
                }
                
                requestStatus = .fail(error: error as! ImageProcessor.Error)
            }
        }
    }
    
    func exportImage() {
        guard case let .success(imageData) = requestStatus else {
            return
        }
        
        guard let topViewController = getTopViewController() else {
            return
        }
        
        guard let requestImageData = self.imageData else {
            return
        }
        
        let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: tempUrl, withIntermediateDirectories: false, attributes: nil)
            
            let fileUrl = tempUrl.appendingPathComponent(requestImageData.name)
            
            FileManager.default.createFile(atPath: fileUrl.path, contents: imageData)
            
            let activityViewController = UIActivityViewController(activityItems: [ fileUrl ], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = topViewController.view
            
            topViewController.present(activityViewController, animated: true)
        } catch {
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard var topViewController = getRootViewController() else {
            return nil
        }
        
        while let newTopVC = topViewController.presentedViewController {
            topViewController = newTopVC
        }
        
        return topViewController
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene && $0.activationState == .foregroundActive }) as? UIWindowScene else { return nil }
        
        return scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    }
    
    private static func createDefaultWatermarkTextParams() -> ImageProcessor.TextWatermarkParams {
        .init(text            : "",
              fontFamily      : supportedFontFamilies.first,
              fontSize        : 24,
              densityLevel    : .medium,
              color           : "000000",
              opacity         : 1,
              rotationAngle   : 0,
              isFontItalic    : false,
              fontWeight      : .w400,
              shadowOpacity   : 0,
              shadowBlurRadius: 0,
              shadowOffsetX   : 0,
              shadowOffsetY   : 0,
              shadowColor     : "000000",
              fontDecorations : [],
              strokeColor     : "000000",
              strokeOpacity   : 0)
    }
    
    private static func createDefaultCustomWatermarkParams() -> ImageProcessor.CustomWatermarkParams {
        .init(imageData    : ImageProcessor.ImageData(data: Data(), mimeType: "", name: ""),
              opacity      : 1,
              rotationAngle: 0,
              densityLevel : .medium)
    }
    
    enum ControlsType {
        case textWatermark
        case customWatermark
    }
    
    enum RequestStatus {
        case idle
        case pending
        case success(data : Data)
        case fail   (error: ImageProcessor.Error)
    }
}

extension ViewModel : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let data = (info[.editedImage] as? UIImage)?.pngData() else { return }
        
        let name     = UUID().uuidString.appending(".png")
        let mimeType = "image/png"
        
        let imageData = ImageProcessor.ImageData(data: data, mimeType: mimeType, name: name)
        
        if picker === imagePicker {
            self.imageData = imageData
        } else if picker === watermarkImagePicker {
            self.watermarkCustomParams.imageData = imageData
        }
    }
}

extension ViewModel : PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }
        
        provider.loadObject(ofClass: UIImage.self) { image, error in
            guard let data = (image as? UIImage)?.pngData() else {
                return
            }
            
            let fileName = UUID().uuidString.appending(".png")
            
            DispatchQueue.main.async {
                let imageData = ImageProcessor.ImageData(data: data, mimeType: "image/png", name: fileName)
                
                if picker === self.imagePicker {
                    self.imageData = imageData
                } else if picker === self.watermarkImagePicker {
                    self.watermarkCustomParams.imageData = imageData
                }
            }
        }
    }

}
