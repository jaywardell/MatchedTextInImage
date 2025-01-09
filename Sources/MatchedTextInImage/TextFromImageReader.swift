//
//  TextFromImageReader.swift
//  VisionTextExtractionTests
//
//  Created by Joseph Wardell on 12/23/24.
//

import Vision

extension CGImage {
    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

public actor TextFromImageReader {
    let image: CGImage
    private(set) var observations: [TextRegion]?
    
    public init(image: CGImage) {
        self.image = image
    }
        
    public struct TextRegion: Identifiable, Sendable {
        public let string: String
        public let rect: CGRect
        public let confidence: Double
        
        public var id: String {
            string + rect.debugDescription
        }
        
        init?(observation: VNRecognizedTextObservation, in size: CGSize) {
            guard let text = observation.topCandidates(1).first else { return nil }
 
            self.string = text.string
            self.confidence = Double(text.confidence)
            
            self.rect = CGRect(
                origin: CGPoint(
                    x: observation.boundingBox.minX * size.width,
                    y: size.height - (observation.boundingBox.minY * size.height) - (observation.boundingBox.height) * size.height
                ),
                size: CGSize(
                    width: (observation.boundingBox.width) * size.width,
                    height: (observation.boundingBox.height) * size.height
                )
            )

        }
    }
    
    private func retrieveObservations() async throws -> [TextRegion] {
        if let observations { return observations }
        
        let obs: [TextRegion] = try await withCheckedThrowingContinuation { continuation in
            
            let request = VNRecognizeTextRequest { [image = self.image] received, error in
                // make sure there were no errors
                if let error { return continuation.resume(throwing: error) }
                
                let obs = (received.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { TextRegion.init(observation: $0, in: image.size) }
                
                continuation.resume(returning: obs)
            }

            Task {
                do {
                    let handler = VNImageRequestHandler(cgImage: image, options: [:])
                    try handler.perform([request])
                }
                catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        self.observations = obs
        
        return obs
    }
            
    public func observations(withConfidence confidenceThreshold: Double = 0.5) async throws -> [TextRegion] {
        try await retrieveObservations()
            .filter { $0.confidence >= confidenceThreshold }
    }

    public func text(withConfidence confidenceThreshold: Double = 0.5, separator: String = "") async throws -> String {
        try await observations(withConfidence: confidenceThreshold)
            .map(\TextRegion.string)
            .joined(separator: separator)
    }
}
