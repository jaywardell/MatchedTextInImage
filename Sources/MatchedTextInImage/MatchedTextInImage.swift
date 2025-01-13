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
    let obscure: (_ context: inout GraphicsContext,
                    _ targetRect: CGRect,
                    _ imageSize: CGSize) -> Void

    @Environment(\.matchedTextFilter) var matchedTextFilter
    
    /// Create a MatchedTextInImage instance
    /// This View will present a CGImage and highlight all regions that match
    /// the text in the invironment variable matchedTextFilter.
    ///
    /// - Parameters:
    ///   - image: the image that will be shown
    ///   - obscure: a method that explains how a GraphicsContext should alter
    ///   the parts of the image that don't match the filter string in matchedTextFilter
    public init(image: CGImage,
                obscure: @escaping (_: inout GraphicsContext, _: CGRect, _: CGSize) -> Void = Self.defaultObscureImage) {
        self.image = image
        self.obscure = obscure
    }
    
    public var body: some View {
        ImageWithHighlightedText(image: image, highlighted: matchedTextFilter, highlight: obscure)
    }
}

public extension MatchedTextInImage {
    
    #if canImport(AppKit)
    init?(_ nsImage: NSImage, obscure: @escaping (_ context: inout GraphicsContext,
                                                  _ targetRect: CGRect,
                                                  _ imageSize: CGSize) -> Void = Self.defaultObscureImage) {
        
        guard let image = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        self.init(image: image,
                  obscure: obscure)
    }
    #elseif canImport(UIKit)
    init?(_ uiimage: UIImage, obscure: @escaping (_ context: inout GraphicsContext,
                                                  _ targetRect: CGRect,
                                                  _ imageSize: CGSize) -> Void = Self.defaultObscureImage) {
        
        guard let image = uiimage.cgImage else { return nil }
        self.init(image: image,
                  obscure: obscure)
    }
    #endif
}


// MARK: -

public extension MatchedTextInImage {
    static func defaultObscureImage(_ context: inout GraphicsContext,
                                 _ targetRect: CGRect,
                                 _ imageSize: CGSize) -> Void {
        context.addFilter(.grayscale(1))
    }
}
