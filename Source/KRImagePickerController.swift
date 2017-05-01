//
//  KRImagePickerController.swift
//  KRImagePickerControllerExample
//
//  Created by ulian_onua on 4/4/17.
//  Copyright © 2017 ulian_onua. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import Photos


let photoLibraryIsNotAvailable = "Photo Library is not available"
let cameraIsNotAvailable = "Camera is not available"
let savedPhotosAlbumIsNotAvailable = "Saved photos album is not available"
let parsingVideoError = "Video error"
let getThumbnailError = "Cannot create thumbnail error"

enum KRImagePickerControllerError : Error {
    case sourceTypeIsNotAvalable(String)
    case operationWasCancelled
    case errorPickingImage
    case errorPickingVideo
    case genericError(String)
}

enum MediaCompletion <Value> {
    case success(Value)
    case failure(KRImagePickerControllerError)
}

//typealias ImageCompletion = (UIImage?, KRImagePickerControllerError?) -> Void
typealias ImageCompletion = (MediaCompletion<Media>) -> Void

class KRImagePickerController : NSObject {
    
    static var imagePickerController : KRImagePickerController? = nil

    var imagePicker : UIImagePickerController =  UIImagePickerController()
    
    
    fileprivate override convenience init() {
        self.init(type:.image, sourceType: .camera)
    }
    
    fileprivate init(sourceType : UIImagePickerControllerSourceType) {
        super.init()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = [kUTTypeImage as String]
    }
    
    fileprivate init(type: MediaType, sourceType : UIImagePickerControllerSourceType) {
        super.init()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        switch type {
        case .image:
            imagePicker.mediaTypes = [kUTTypeImage as String]
            break
        case .video:
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            break
        case .all:
            imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            break
        }
    }
    
    fileprivate static var imagePickerCompletion : ImageCompletion?
    
    class func pickFromPhotoLibrary(viewController : UIViewController, completion : @escaping ImageCompletion) {
        pick(from: viewController, sourceType: .photoLibrary, completion: completion)
    }
    // Pick from Camera only for take picture
    class func pickFromCamera(viewController : UIViewController, completion : @escaping ImageCompletion) {
        pick(from: viewController, sourceType: .camera, completion: completion)
    }
    
    
    class func pickFromSavedPhotosAlbum(viewController : UIViewController, completion : @escaping ImageCompletion) {
        pick(from: viewController, sourceType: .savedPhotosAlbum, completion: completion)
    }
    
    
    class func pick(from viewController : UIViewController, sourceType : UIImagePickerControllerSourceType, mediaType: MediaType = .image ,completion : @escaping ImageCompletion) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            completion(.failure(errorForUnavailableSourceType(sourceType: sourceType)))
            return
        }
        guard let imagePicker = KRImagePickerController.getImagePickerController(sourceType: sourceType, mediaType: mediaType) else {return}
       
        imagePickerCompletion = completion
        viewController.present(imagePicker.imagePicker, animated: true, completion: nil)
    }
    
    
    //MARK: Helpers
    
    fileprivate class func errorForUnavailableSourceType(sourceType : UIImagePickerControllerSourceType) -> KRImagePickerControllerError {
        switch sourceType {
        case .camera:
            return .sourceTypeIsNotAvalable(cameraIsNotAvailable)
        case .photoLibrary:
            return .sourceTypeIsNotAvalable(photoLibraryIsNotAvailable)
        case .savedPhotosAlbum:
            return .sourceTypeIsNotAvalable(savedPhotosAlbumIsNotAvailable)
        }
    }
    
    fileprivate class func getImagePickerController(sourceType: UIImagePickerControllerSourceType, mediaType: MediaType) -> KRImagePickerController? {
        guard let imagePicker = imagePickerController else {
            imagePickerController = KRImagePickerController(type: mediaType, sourceType: sourceType)
            return imagePickerController
        }
        return imagePicker
    }
    
    fileprivate class func clearMemory() {
        imagePickerController = nil
    }
    
    fileprivate func mediaName(info: [String: Any]) -> String {
        // TODO: Get media name here
        // If media is taken from camera, set default name. Otherwise, get name
        if imagePicker.sourceType == .camera {
            return "camera_photo"
        }
        if let imageURL = info[UIImagePickerControllerReferenceURL] as? URL {
            let result = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
            let asset = result.firstObject
            print(asset?.value(forKey: "filename") ?? "")
            return asset?.value(forKey: "filename") as! String
        }
        return ""
    }
    
    fileprivate func didFinishPickingImage(picker:UIImagePickerController, info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            KRImagePickerController.imagePickerCompletion?(.failure(.errorPickingImage))
            return
        }
        DispatchQueue.global(qos: .background).async {
            guard let data = UIImageJPEGRepresentation(image, 0.5) else { return }
            DispatchQueue.main.async { [unowned self] in
                let media = Media(name: self.mediaName(info: info) ,
                                  thumbnailImage: image,
                                  type: .image,
                                  data: data)
                picker.dismiss(animated: true, completion: nil)
                KRImagePickerController.imagePickerCompletion?(.success(media))
                defer {
                    KRImagePickerController.clearMemory()
                }
            }
        }
    }
    
    
    fileprivate func didFinishPickingVideo(picker: UIImagePickerController, info: [String : Any]) {
        // Get video URL and
        guard let videoURL = info[UIImagePickerControllerMediaURL] as? URL else {
            KRImagePickerController.imagePickerCompletion?(.failure(.errorPickingVideo))
            return
        }
       
        do {
            let data = try Data(contentsOf: videoURL)
            guard let thubmnailImage = thumbnailImage(filePath: videoURL) else {
                KRImagePickerController.imagePickerCompletion?(.failure(.genericError(getThumbnailError)))
                return
            }
            let media = Media(name: self.mediaName(info: info) ,
                              thumbnailImage: thubmnailImage,
                              type: .video,
                              data: data,
                              url: videoURL)
            KRImagePickerController.imagePickerCompletion?(.success(media))
        } catch  {
            KRImagePickerController.imagePickerCompletion?(.failure(.genericError(parsingVideoError)))
        }
    
        picker.dismiss(animated: true, completion: nil)
        defer {
            KRImagePickerController.clearMemory()
        }
    }
    
}

extension KRImagePickerController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])  {
        // TODO: Get name of image, and video thumbnail as well as video url
        if picker.mediaTypes == [kUTTypeImage as String] {
            didFinishPickingImage(picker: picker, info: info)
        } else {
            didFinishPickingVideo(picker: picker, info: info)
        }
    }
    
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController)   {
        picker.dismiss(animated: true, completion: nil)
        KRImagePickerController.imagePickerCompletion?(.failure(.operationWasCancelled))
        KRImagePickerController.clearMemory()
    }
}

extension KRImagePickerController {
    fileprivate func thumbnailImage(filePath: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: filePath , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            return UIImage(cgImage: cgImage)
            
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}
