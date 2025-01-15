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
    let obscure: (_ context: inout GraphicsContext,
                    _ targetRect: CGRect,
                    _ imageSize: CGSize) -> Void
        
    @State private var foundText = [String]()
    @State private var textRegions: [TextFromImageReader.TextRegion]?
    
    init(image: CGImage,
         highlighted: String,
         highlight: @escaping (_: inout GraphicsContext, _: CGRect, _: CGSize) -> Void) {
        self.image = image
        self.highlighted = highlighted
        self.obscure = highlight
    }
    
    private var matchingTextRegions: [TextFromImageReader.TextRegion]? {
        textRegions?.filter { region in
            // we want to be very lenient in how we match
            // the string that the user is searching for
            // since the instance of the filter
            // could cross between text regions
            highlighted.words().contains {
                region.string.localizedCaseInsensitiveContains($0)
            }
        }
    }
            
    var body: some View {
        ImageWithHighlightedRegions(
            image: image,
            regions: matchingTextRegions?.map(\.rect) ?? [],
            highlighted: highlighted,
            outlineRegions: true,
            obscure: obscure,
            highlight: { _, _, _ in }
            )
            .accessibilityLabel("Image")
            .accessibilityValue(foundText.joined(separator: " "))
            .task(priority: .background, findText)
    }
    
    private func findText() async {
        guard nil == textRegions else { return }
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

// MARK: -

extension ImageWithHighlightedText {
    
    #if canImport(AppKit)
    init?(nsImage: NSImage, highlighted: String,
          highlight: @escaping (_: inout GraphicsContext, _: CGRect, _: CGSize) -> Void) {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        self.image = cgImage
        self.highlighted = highlighted
        self.obscure = highlight
    }
    #elseif canImport(UIKit)
    init?(uiImage: UIImage, highlighted: String, highlight: @escaping (_ context: inout GraphicsContext,
                                                             _ targetRect: CGRect,
                                                             _ imageSize: CGSize) -> Void) {
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
    ImageWithHighlightedText("bernie", highlighted: "at", highlight: MatchedTextInImage.defaultObscureImage(_:_:_:))
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
