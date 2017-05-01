//
//  Media.swift
//  KRImagePickerControllerExample
//
//  Created by iOS Developer on 4/30/17.
//  Copyright © 2017 ulian_onua. All rights reserved.
//

import Foundation
import UIKit

struct Media {
    let type: MediaType
    let thumbnailImage: UIImage
    let name: String
    var url : URL?
    let data: Data
    
    init (name: String, thumbnailImage: UIImage, type: MediaType, data: Data, url: URL? = nil) {
        self.name = name
        self.thumbnailImage = thumbnailImage
        self.type = type
        self.data = data
        self.url = url
    }
}

enum MediaType: CustomStringConvertible {
    case image, video
    var description: String {
        switch self {
        case .image:
            return "IMAGE"
        case .video:
            return "VIDEO"
        }
    }
    static let allValues = [image, video]
}
