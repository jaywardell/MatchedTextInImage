//
//  ImageWIthFilteredText.swift
//  toss
//
//  Created by Joseph Wardell on 12/30/24.
//

import SwiftUI

struct ImageWithHighlightedText: View {
    
    let image: CGImage
    let highlighted: String
    let highlight: (_ context: inout GraphicsContext,
                    _ targetRect: CGRect,
                    _ imageSize: CGSize) -> Void
        
    @State private var foundText = [String]()
    @State private var textRegions: [TextFromImageReader.TextRegion] = []
    
    init(image: CGImage,
         highlighted: String,
         highlight: @escaping (_: inout GraphicsContext, _: CGRect, _: CGSize) -> Void = Self.defaultHighlight) {
        self.image = image
        self.highlighted = highlighted
        self.highlight = highlight
    }
    
    private var matchingTextRegions: [TextFromImageReader.TextRegion] {
        textRegions.filter { region in
            // we want to be very lenient in how we match
            // the string that the user is searching for
            // since the instance of the filter
            // could cross between text regions
            highlighted.words().contains {
                region.string.localizedCaseInsensitiveContains($0)
            }
        }
    }
    
    private var swiftUIImage: Image { Image(image, scale: 1, orientation: .up, label: Text(foundText.joined(separator: " "))) }
    
    private func outsetRect(for region: TextFromImageReader.TextRegion) -> CGRect {
        let outset = region.rect.height * 0.1
        return CGRectInset(region.rect, -outset, -outset)
    }
        
    private var results: some View {
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
                highlight(&backgroundContext, targetRect, image.size)
                backgroundContext.draw(swiftUIImage, in: targetRect)
            }
                        
            for region in matchingTextRegions {
                let toclip = outsetRect(for: region)
                var maskedContext = context

                // draw each region straight from the original image
                maskedContext.clip(to: Path(toclip))
                maskedContext.draw(swiftUIImage, in: targetRect)

                // and outline it if it's above a certain minimal threshold
                if toclip.size.height * scalar > 20 {
                    context.stroke(Path(toclip), with: .color(white: 1), lineWidth: 3)
                    context.stroke(Path(toclip), with: .color(white: 0), lineWidth: 1)
                }
            }
        }
    }
        
    var body: some View {
        results
            .accessibilityLabel("Image")
            .accessibilityValue(foundText.joined(separator: " "))
            .task(priority: .background) {
                guard foundText.isEmpty else { return }
                do {
                    let reader = TextFromImageReader(image: image)
                    self.foundText = try await reader.text(separator: "\n").components(separatedBy: "\n")
                    self.textRegions = try await reader.observations()
                }
                catch {
                    print("Error pulling text from image")
                    print(error.localizedDescription)
                }
            }
    }
}

// MARK: -

extension ImageWithHighlightedText {
    static func defaultHighlight(_ context: inout GraphicsContext,
                                 _ targetRect: CGRect,
                                 _ imageSize: CGSize) -> Void {
        context.addFilter(.grayscale(1))
    }
}

// MARK: -

extension ImageWithHighlightedText {
    
    #if canImport(AppKit)
    init?(nsImage: NSImage, highlighted: String,
          highlight: @escaping (_: inout GraphicsContext, _: CGRect, _: CGSize) -> Void) {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        self.image = cgImage
        self.highlighted = highlighted
        self.highlight = highlight
    }
    #elseif canImport(UIKit)
    init?(uiImage: UIImage, highlighted: String, highlight: @escaping (_ context: inout GraphicsContext,
                                                             _ targetRect: CGRect,
                                                             _ imageSize: CGSize) -> Void = Self.defaultHighlight) {
        guard let cgImage = uiImage.cgImage else { return nil }
        self.image = cgImage
        self.highlighted = highlighted
        self.highlight = highlight
    }
    #endif
    
    init?(_ imageName: String, highlighted: String,
          highlight: @escaping (_: inout GraphicsContext, _: CGRect, _: CGSize) -> Void) {

#if canImport(AppKit)
        let nsImage = NSImage(imageLiteralResourceName: imageName)
        guard let fromResouce = ImageWithHighlightedText(nsImage: nsImage, highlighted: highlighted, highlight: highlight)
        else { return nil }
#elseif canImport(UIKit)
        guard let uiImage = UIImage(named: imageName),
              let fromResouce = ImageWithHighlightedText(uiImage: uiImage, highlighted: highlighted, highlight: highlight)
        else { return nil }
#endif
        self = fromResouce
    }
}

// MARK: -

#Preview {
    ImageWithHighlightedText("bernie", highlighted: "at", highlight: ImageWithHighlightedText.defaultHighlight)
        .padding()
        .padding(.bottom)
}

// MARK: -

fileprivate extension String {

    func words() -> [String] {
        
        // there are smarter ways to do this,
        // but this works for our purposes here
        self.components(separatedBy: .whitespacesAndNewlines)
    }
}
