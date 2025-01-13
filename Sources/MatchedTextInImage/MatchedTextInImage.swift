//
//  File.swift
//  MatchedTextInImage
//
//  Created by Joseph Wardell on 1/8/25.
//

import SwiftUI
import MatchedText

struct MatchedTextInImage: View {
    
    let image: CGImage
    let highlight: (_ context: inout GraphicsContext,
                    _ targetRect: CGRect,
                    _ imageSize: CGSize) -> Void

    @Environment(\.matchedTextFilter) var matchedTextFilter
    
    var body: some View {
        ImageWithHighlightedText(image: image, highlighted: matchedTextFilter, highlight: highlight)
    }
}
