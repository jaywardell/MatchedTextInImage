//
//  File.swift
//  MatchedTextInImage
//
//  Created by Joseph Wardell on 1/8/25.
//

import SwiftUI
import MatchedText

public struct MatchedTextInImage: View {
    
    let image: CGImage
    let highlight: (_ context: inout GraphicsContext,
                    _ targetRect: CGRect,
                    _ imageSize: CGSize) -> Void

    @Environment(\.matchedTextFilter) var matchedTextFilter
    
    public var body: some View {
        ImageWithHighlightedText(image: image, highlighted: matchedTextFilter, highlight: highlight)
    }
}

public extension MatchedTextInImage {
    
    #if canImport(AppKit)
    init?(_ nsImage: NSImage, highlight: @escaping (_ context: inout GraphicsContext,
                                                  _ targetRect: CGRect,
                                                  _ imageSize: CGSize) -> Void = Self.defaultHighlight) {
        
        guard let image = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        self.init(image: image,
                  highlight: highlight)
    }
    #elseif canImport(UIKit)
    init?(_ uiimage: UIImage, highlight: @escaping (_ context: inout GraphicsContext,
                                                  _ targetRect: CGRect,
                                                  _ imageSize: CGSize) -> Void = Self.defaultHighlight) {
        
        guard let image = uiimage.cgImage else { return nil }
        self.init(image: image,
                  highlight: highlight)
    }
    #endif
}


// MARK: -

public extension MatchedTextInImage {
    static func defaultHighlight(_ context: inout GraphicsContext,
                                 _ targetRect: CGRect,
                                 _ imageSize: CGSize) -> Void {
        context.addFilter(.grayscale(1))
    }
}
