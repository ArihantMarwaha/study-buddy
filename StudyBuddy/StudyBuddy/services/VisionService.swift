//
//  VisionService.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import Foundation
import SwiftUI
@preconcurrency import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
internal import Combine

@MainActor
class VisionService: ObservableObject {
    @Published var isProcessing = false
    @Published var recognizedText = ""
    @Published var processingProgress: Double = 0.0
    
    private let textRecognitionQueue = DispatchQueue(label: "com.studybuddy.textrecognition")
    
    // MARK: - Text Recognition
    func recognizeText(from image: NSImage) async throws -> (text: String, confidence: Float) {
        isProcessing = true
        processingProgress = 0.0
        defer { isProcessing = false }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw VisionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                self.processTextRecognitionResults(request.results, continuation: continuation)
            }
            
            // Configure for handwriting
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            // For WWDC 2025's enhanced handwriting recognition
            if #available(macOS 15.0, *) {
                request.revision = VNRecognizeTextRequestRevision3 // Simulated newer revision
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            textRecognitionQueue.async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processTextRecognitionResults(
        _ results: [Any]?,
        continuation: CheckedContinuation<(text: String, confidence: Float), Error>
    ) {
        guard let observations = results as? [VNRecognizedTextObservation] else {
            continuation.resume(throwing: VisionError.noTextFound)
            return
        }
        
        var recognizedStrings: [String] = []
        var totalConfidence: Float = 0
        var observationCount = 0
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            recognizedStrings.append(topCandidate.string)
            totalConfidence += topCandidate.confidence
            observationCount += 1
            
            DispatchQueue.main.async {
                self.processingProgress = Double(observationCount) / Double(observations.count)
            }
        }
        
        let finalText = recognizedStrings.joined(separator: "\n")
        let averageConfidence = observationCount > 0 ? totalConfidence / Float(observationCount) : 0
        
        DispatchQueue.main.async {
            self.recognizedText = finalText
            continuation.resume(returning: (text: finalText, confidence: averageConfidence))
        }
    }
    
    // MARK: - Smudge Detection
    func detectSmudges(in image: NSImage) async -> (hasSmudges: Bool, cleanedImage: NSImage?) {
        guard let inputImage = CIImage(data: image.tiffRepresentation ?? Data()) else {
            return (false, nil)
        }
        
        // Simulate smudge detection using Core Image filters
        let context = CIContext()
        
        // Apply edge detection to find smudges
        guard let edgeDetector = CIFilter(name: "CIEdges") else {
            return (false, nil)
        }
        edgeDetector.setValue(inputImage, forKey: kCIInputImageKey)
        
        guard let edgeImage = edgeDetector.outputImage else {
            return (false, nil)
        }
        
        // Analyze for smudges (simplified - in real implementation would use ML)
        let smudgeDetected = analyzeForSmudges(edgeImage, context: context)
        
        if smudgeDetected {
            // Attempt to clean the image
            let cleanedImage = enhanceHandwrittenImage(inputImage, context: context)
            return (true, cleanedImage)
        }
        
        return (false, nil)
    }
    
    private func analyzeForSmudges(_ image: CIImage, context: CIContext) -> Bool {
        // Simplified smudge detection
        // In real implementation, would use Core ML or advanced image processing
        return Bool.random() // Simulated for demo
    }
    
    // MARK: - Image Enhancement
    func enhanceHandwrittenImage(_ inputImage: CIImage, context: CIContext) -> NSImage? {
        // Apply filters to enhance handwritten text
        var outputImage = inputImage
        
        // 1. Increase contrast
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.5, forKey: kCIInputContrastKey)
            contrastFilter.setValue(0.1, forKey: kCIInputBrightnessKey)
            outputImage = contrastFilter.outputImage ?? outputImage
        }
        
        // 2. Sharpen
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.8, forKey: kCIInputSharpnessKey)
            outputImage = sharpenFilter.outputImage ?? outputImage
        }
        
        // 3. Reduce noise
        if let noiseReduction = CIFilter(name: "CINoiseReduction") {
            noiseReduction.setValue(outputImage, forKey: kCIInputImageKey)
            noiseReduction.setValue(0.1, forKey: "inputNoiseLevel")
            noiseReduction.setValue(1.0, forKey: "inputSharpness")
            outputImage = noiseReduction.outputImage ?? outputImage
        }
        
        // Convert back to NSImage
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
    
    // MARK: - Document Scanner Integration
    func processScannedDocument(_ images: [NSImage]) async throws -> [HandwrittenNote] {
        var processedNotes: [HandwrittenNote] = []
        
        for (index, image) in images.enumerated() {
            processingProgress = Double(index) / Double(images.count)
            
            // Process each page
            let (text, confidence) = try await recognizeText(from: image)
            let (hasSmudges, cleanedImage) = await detectSmudges(in: image)
            
            var handwrittenNote = HandwrittenNote(
                imageData: image.tiffRepresentation ?? Data()
            )
            handwrittenNote.recognizedText = text
            handwrittenNote.smudgeDetected = hasSmudges
            
            if let cleaned = cleanedImage,
               let cleanedData = cleaned.tiffRepresentation {
                handwrittenNote.enhancedImageData = cleanedData
            }
            
            processedNotes.append(handwrittenNote)
        }
        
        processingProgress = 1.0
        return processedNotes
    }
    
    // MARK: - Math Recognition (Future Feature)
    func recognizeMathematicalExpressions(from image: NSImage) async throws -> [MathExpression] {
        // Placeholder for math recognition
        // Would integrate with specialized math recognition models
        return []
    }
}

// MARK: - Supporting Types
enum VisionError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in image"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}

struct MathExpression {
    let latex: String
    let boundingBox: CGRect
    let confidence: Float
}
