//
//  SwiftUIView.swift
//  MatchedTextInImage
//
//  Created by Joseph Wardell on 1/14/25.
//

import SwiftUI

struct ImageWithHighlightedRegions: View {
    
    let image: CGImage
    let regions: [CGRect]
    let highlighted: String
    let foundText: [String]
    let outlineRegions: Bool
    let obscure: (_ context: inout GraphicsContext,
                    _ targetRect: CGRect,
                    _ imageSize: CGSize) -> Void
    let highlight: (_ context: inout GraphicsContext,
                    _ targetRect: CGRect,
                    _ imageSize: CGSize) -> Void

    private var swiftUIImage: Image { Image(image, scale: 1, orientation: .up, label: Text(foundText.joined(separator: " "))) }

    private func outsetRect(for rect: CGRect) -> CGRect {
        let outset = rect.height * 0.1
        return CGRectInset(rect, -outset, -outset)
    }

    var body: some View {
        Canvas { context, size in
            
            let targetRect = CGRect(origin: .zero, size: image.size)
            
            // scale the coordinate system
            let scalar = min(size.width / image.size.width, size.height/image.size.height)
            context.translateBy(
                x: (size.width - image.size.width * scalar)/2,
                y: (size.height - image.size.height * scalar)/2
            )
            context.scaleBy(x: scalar, y: scalar)
            
            // draw the image itself
            var backgroundContext = context
            if highlighted.isEmpty {
                // solid if there are no matches
                backgroundContext.draw(swiftUIImage, in: targetRect)
            }
            else {
                // otherwise blurry and desaturated
                backgroundContext.clip(to: Path(targetRect))
                obscure(&backgroundContext, targetRect, image.size)
                backgroundContext.draw(swiftUIImage, in: targetRect)
            }
                        
            for region in regions {
                let toclip = outsetRect(for: region)
                var maskedContext = context

                // draw each region straight from the original image
                maskedContext.clip(to: Path(toclip))
                highlight(&backgroundContext, targetRect, image.size)
                maskedContext.draw(swiftUIImage, in: targetRect)

                // and outline it if it's above a certain minimal threshold
                if outlineRegions && toclip.size.height * scalar > 20 {
                    context.stroke(Path(toclip), with: .color(white: 1), lineWidth: 3)
                    context.stroke(Path(toclip), with: .color(white: 0), lineWidth: 1)
                }
            }
        }
    }
}

//#Preview {
//    SwiftUIView()
//}
