//
//  ImageExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/28.
//

import SwiftUI

// MARK: -
internal protocol ImageResourceable {
    static func getImageResource(_ name: String) -> ImageResource
}

internal extension ImageResourceable {
    static func getImageResource(_ name: String) -> ImageResource {
        let bundle = SDKStringBundleProvider.bundle
        return ImageResource(
            name: name, bundle: bundle
        )
    }
}

// MARK: -
extension UIImage: ImageResourceable {
    
    static func named(_ name: String) -> UIImage {
        let resource = getImageResource(name)
        return UIImage(resource: resource)
    }
    
}

@available(iOS 13.0, *)
extension Image: ImageResourceable {
    
    static func named(_ name: String) -> Image {
        let resource = getImageResource(name)
        return Image(resource)
    }
    
}
