//
//  ImageExtension.swift
//  GameWrapper
//
//  Created by arvin on 2025/7/28.
//

import SwiftUI

// MARK: -
@available(iOS 13.0, *)
internal extension Image {
    
    static func named(_ name: String) -> Image {
        let bundle = Bundle(for: GameWebWrapper.self)
        return Image(name, bundle: bundle)
    }
    
}
