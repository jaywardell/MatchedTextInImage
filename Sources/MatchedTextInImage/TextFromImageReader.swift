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
    private(set) var observations: [VNRecognizedTextObservation]?
    public init(image: CGImage) {
        self.image = image
    }
        
    private func retrieveObservations() async throws -> [VNRecognizedTextObservation] {
        if let observations { return observations }
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let request = VNRecognizeTextRequest { [weak self] received, error in
                Task {
                    await self?.process(results: received, error: error, continuation: continuation)
                }
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
    }
    
    private func process(
        results received: VNRequest,
        error: Swift.Error?,
        continuation:  CheckedContinuation<[VNRecognizedTextObservation], any Swift.Error>
    ) {
        
        // make sure there were no errors
        if let error { return continuation.resume(throwing: error) }
                                
        let obs = received.results as? [VNRecognizedTextObservation] ?? []
        self.observations = received.results as? [VNRecognizedTextObservation] ?? []
        
        continuation.resume(returning: obs)

    }
    
    func observations(withConfidence confidenceThreshold: Double = 0.5) async throws -> [String] {
        try await retrieveObservations()
            .compactMap { $0.topCandidates(1).first }
            // TODO: this can probably be switched for a slight optimization
            .filter { $0.confidence >= VNConfidence(confidenceThreshold) }
            .map(\.string)
    }

    public struct TextRegion: Identifiable {
        public let string: String
        public let rect: CGRect
        
        public var id: String {
            string + rect.debugDescription
        }
        
        init?(observation: VNRecognizedTextObservation, in size: CGSize) {
            guard let string = observation.topCandidates(1).first?.string else { return nil }
 
            self.string = string
            
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
    public func mappedObservations(withConfidence confidenceThreshold: Double = 0.5) async throws -> [TextRegion] {
        try await retrieveObservations()
            .filter { $0.confidence >= VNConfidence(confidenceThreshold) }
            .compactMap { TextRegion.init(observation: $0, in: image.size) }
    }
    
    public func text(withConfidence confidenceThreshold: Double = 0.5, separator: String = "") async throws -> String {
        try await observations(withConfidence: confidenceThreshold)
            .joined(separator: separator)
    }
}
