//
//  ImageExtension.swift
//  GrowthKit
//
//  Created by arvin on 2025/7/28.
//

import SwiftUI

internal protocol ImageResourceable {
    static func getImageResource(_ name: String) -> ImageResource
}

internal extension ImageResourceable {
    static func getImageResource(_ name: String) -> ImageResource {
        let bundle = Bundle(for: GameWebWrapper.self)
        return ImageResource(name: name, bundle: bundle)
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
        //return Image(name, bundle: bundle)
        return Image(resource)
    }
    
}
