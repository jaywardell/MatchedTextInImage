#  MatchedTextInImage

This is a library that lets you present an image and show the area that contains match that matches a search string.

## Usage

To present an image, use a `MatchedTextInImage` View.  It takes either a `CGImage`, `UIImage` or `NSImage`.
Then pass a string down through the environment via the `matchedTextFilter` environment value.
The image will be presented and all parts of the image will be in black and white aside from the areas that contain text that matches the filter string in `matchedTextFilter`

    MatchedTextInImage(image)
        .environment(\.matchedTextFilter, "filter")


### changing the way non-matching image regions are altered

You can pass a custom function into the init to change the way the image is drawn when it doesn't match the filter string:

        MatchedTextInImage(image) {
            context.addFilter(.blur(radius: 10))
            context.addFilter(.saturation(0.8))
        }


