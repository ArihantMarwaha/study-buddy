//
//  AIService.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//


import SwiftUI
import Foundation
import FoundationModels
import Speech
import AVFoundation
internal import Combine
internal import UniformTypeIdentifiers
import Vision

@MainActor
class AIService: ObservableObject {
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var streamingResponse = ""
    @Published var processingProgress: Double = 0.0
    @Published var speechRecognitionAuthStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Foundation Models
    private let systemModel = SystemLanguageModel.default
    private var currentSession: LanguageModelSession?
    var modelAvailability: SystemLanguageModel.Availability
    
    // MARK: - Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Translation Support
    private var availableLanguages: [String] = [
        "en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh", "ar", "hi"
    ]
    
    init() {
        self.modelAvailability = systemModel.availability
        setupSpeechRecognition()
    }
    
    // MARK: - Foundation Models Setup
    func checkModelAvailability() -> Bool {
        modelAvailability = systemModel.availability
        return modelAvailability == .available
    }
    
    private func createSession(with instructions: String? = nil) -> LanguageModelSession {
        let systemInstructions = instructions ?? "You are an intelligent study assistant that helps students learn effectively."
        return LanguageModelSession(instructions: Instructions(systemInstructions))
    }
    
    // MARK: - Enhanced Text Processing
    func enhanceText(_ text: String, style: TextEnhancementStyle) async -> String {
        guard checkModelAvailability() else {
            return "AI model unavailable"
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let instructions = style.instructions
            let session = createSession(with: instructions)
            
            let prompt = """
            Please enhance the following text according to the specified style:
            
            Text: \(text)
            
            Enhancement Style: \(style.description)
            """
            
            let response = try await session.respond(to: Prompt(prompt))
            return response.content
            
        } catch {
            return "Error enhancing text: \(error.localizedDescription)"
        }
    }
    
    func generateStructuredContent(_ text: String, format: ContentFormat) async -> String {
        guard checkModelAvailability() else {
            return "AI model unavailable"
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let instructions = """
            You are an expert at creating well-structured educational content.
            Format the content according to the specified format with proper markdown.
            """
            
            let session = createSession(with: instructions)
            
            let prompt = """
            Convert the following content into \(format.description):
            
            \(text)
            
            Use proper markdown formatting including:
            - Headers (# ## ###)
            - Bullet points and numbered lists
            - **Bold** and *italic* text
            - Code blocks if needed
            - Tables if appropriate
            
            Make it well-organized and study-friendly.
            """
            
            let response = try await session.respond(to: Prompt(prompt))
            return response.content
            
        } catch {
            return "Error generating structured content: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Advanced Speech Recognition
    private func setupSpeechRecognition() {
        speechRecognitionAuthStatus = SFSpeechRecognizer.authorizationStatus()
        
        if speechRecognitionAuthStatus == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    self?.speechRecognitionAuthStatus = status
                }
            }
        }
    }
    
    func startRealTimeTranscription() -> AsyncStream<String> {
        return AsyncStream { continuation in
            guard speechRecognitionAuthStatus == .authorized else {
                continuation.finish()
                return
            }
            
            do {
                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = recognitionRequest else {
                    continuation.finish()
                    return
                }
                
                recognitionRequest.shouldReportPartialResults = true
                
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    recognitionRequest.append(buffer)
                }
                
                audioEngine.prepare()
                try audioEngine.start()
                
                recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                    if let result = result {
                        continuation.yield(result.bestTranscription.formattedString)
                    }
                    
                    if error != nil || result?.isFinal == true {
                        continuation.finish()
                    }
                }
                
            } catch {
                continuation.finish()
            }
        }
    }
    
    func stopRealTimeTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    func analyzeSpeechContent(_ transcript: String) async -> SpeechAnalysisResult {
        guard checkModelAvailability() else {
            return SpeechAnalysisResult(
                sentiment: "unavailable",
                keyTopics: [],
                actionItems: [],
                speakingPattern: SpeakingPattern.neutral,
                confidence: 0.0,
                suggestions: []
            )
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let instructions = """
            You are an expert speech analyst. Analyze the given transcript for:
            1. Emotional sentiment and tone
            2. Key topics and themes
            3. Action items or tasks mentioned
            4. Speaking patterns (clarity, pace, confidence)
            5. Educational insights and suggestions
            """
            
            let session = createSession(with: instructions)
            
            let prompt = """
            Analyze this speech transcript:
            
            "\(transcript)"
            
            Provide analysis in the following format:
            SENTIMENT: [positive/negative/neutral/mixed]
            KEY_TOPICS: [topic1, topic2, topic3]
            ACTION_ITEMS: [item1, item2, item3]
            SPEAKING_PATTERN: [confident/hesitant/neutral/excited]
            CONFIDENCE_SCORE: [0.0-1.0]
            SUGGESTIONS: [suggestion1, suggestion2, suggestion3]
            """
            
            let response = try await session.respond(to: Prompt(prompt))
            return parseSpeechAnalysis(response.content)
            
        } catch {
            return SpeechAnalysisResult(
                sentiment: "error",
                keyTopics: [],
                actionItems: [],
                speakingPattern: .neutral,
                confidence: 0.0,
                suggestions: []
            )
        }
    }
    
    // MARK: - Translation Services
    func translateText(_ text: String, from sourceLanguage: String, to targetLanguage: String) async -> TranslationResult {
        guard checkModelAvailability() else {
            return TranslationResult(
                originalText: text,
                translatedText: "Translation unavailable",
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                confidence: 0.0
            )
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let instructions = """
            You are a professional translator with expertise in multiple languages.
            Provide accurate, natural translations while preserving meaning and context.
            Consider cultural nuances and idiomatic expressions.
            """
            
            let session = createSession(with: instructions)
            
            let prompt = """
            Translate the following text from \(getLanguageName(sourceLanguage)) to \(getLanguageName(targetLanguage)):
            
            Text: "\(text)"
            
            Provide only the translation without additional commentary.
            Ensure the translation is natural and contextually appropriate.
            """
            
            let response = try await session.respond(to: Prompt(prompt))
            
            return TranslationResult(
                originalText: text,
                translatedText: response.content,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                confidence: 0.95 // AI translation confidence
            )
            
        } catch {
            return TranslationResult(
                originalText: text,
                translatedText: "Translation failed: \(error.localizedDescription)",
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                confidence: 0.0
            )
        }
    }
    
    func detectLanguage(_ text: String) async -> String {
        guard checkModelAvailability() else {
            return "en" // Default to English
        }
        
        do {
            let session = createSession(with: "You are a language detection expert.")
            
            let prompt = """
            Detect the language of this text and respond with only the ISO 639-1 language code (e.g., 'en', 'es', 'fr'):
            
            "\(text)"
            """
            
            let response = try await session.respond(to: Prompt(prompt))
            let detectedLanguage = response.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            return availableLanguages.contains(detectedLanguage) ? detectedLanguage : "en"
            
        } catch {
            return "en"
        }
    }
    
    // MARK: - Enhanced Handwriting Recognition
    func analyzeHandwriting(from imageData: Data) async -> HandwritingAnalysisResult {
        isProcessing = true
        defer { isProcessing = false }
        
        // Use Vision framework for OCR
        guard let image = NSImage(data: imageData),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return HandwritingAnalysisResult(
                recognizedText: "",
                confidence: 0.0,
                hasIssues: true,
                suggestions: ["Invalid image format"],
                enhancedText: ""
            )
        }
        
        do {
            let (recognizedText, confidence) = try await performOCR(on: cgImage)
            
            // Analyze and enhance the recognized text with AI
            let enhancedText = await enhanceHandwritingText(recognizedText)
            let suggestions = await generateHandwritingSuggestions(recognizedText)
            
            return HandwritingAnalysisResult(
                recognizedText: recognizedText,
                confidence: confidence,
                hasIssues: confidence < 0.8,
                suggestions: suggestions,
                enhancedText: enhancedText
            )
            
        } catch {
            return HandwritingAnalysisResult(
                recognizedText: "",
                confidence: 0.0,
                hasIssues: true,
                suggestions: ["OCR processing failed: \(error.localizedDescription)"],
                enhancedText: ""
            )
        }
    }
    
    private func performOCR(on cgImage: CGImage) async throws -> (String, Double) {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: ("", 0.0))
                    return
                }
                
                var recognizedStrings: [String] = []
                var totalConfidence: Float = 0
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    recognizedStrings.append(topCandidate.string)
                    totalConfidence += topCandidate.confidence
                }
                
                let text = recognizedStrings.joined(separator: "\n")
                let avgConfidence = observations.isEmpty ? 0.0 : Double(totalConfidence) / Double(observations.count)
                
                continuation.resume(returning: (text, avgConfidence))
            }
            
            // Configure for better handwriting recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "es-ES", "fr-FR", "de-DE"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func enhanceHandwritingText(_ text: String) async -> String {
        guard !text.isEmpty, checkModelAvailability() else { return text }
        
        do {
            let instructions = """
            You are an expert at cleaning up and enhancing text from handwriting recognition.
            Correct obvious OCR errors, improve grammar, and maintain the original meaning.
            """
            
            let session = createSession(with: instructions)
            
            let prompt = """
            Clean up and enhance this text from handwriting recognition:
            
            "\(text)"
            
            Correct spelling errors, fix grammar, and improve readability while preserving the original meaning.
            """
            
            let response = try await session.respond(to: Prompt(prompt))
            return response.content
            
        } catch {
            return text
        }
    }
    
    private func generateHandwritingSuggestions(_ text: String) async -> [String] {
        guard !text.isEmpty, checkModelAvailability() else { return [] }
        
        do {
            let session = createSession(with: "You are a handwriting analysis expert.")
            
            let prompt = """
            Analyze this handwritten text and provide helpful suggestions:
            
            "\(text)"
            
            Provide 3-5 brief suggestions for:
            - Improving handwriting clarity
            - Better note organization
            - Study techniques based on the content
            """
            
            let response = try await session.respond(to: Prompt(prompt))
            
            return response.content
                .components(separatedBy: .newlines)
                .compactMap { line in
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                }
                .prefix(5)
                .map { String($0) }
            
        } catch {
            return ["Error generating suggestions"]
        }
    }
    
    // MARK: - Chart and Visualization Generation
    func generateChartData(from text: String, chartType: ChartType) async -> ChartData? {
        guard checkModelAvailability() else { return nil }
        
        do {
            let instructions = """
            You are a data visualization expert. Extract numerical data from text and format it for charts.
            """
            
            let session = createSession(with: instructions)
            
            let prompt = """
            Extract data from this text and format it for a \(chartType.rawValue):
            
            "\(text)"
            
            Return data in JSON format with labels and values.
            Example: {"labels": ["A", "B", "C"], "values": [10, 20, 30]}
            """
            
            let response = try await session.respond(to: Prompt(prompt))
            
            // Parse JSON response
            if let jsonData = response.content.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let labels = parsed["labels"] as? [String],
               let values = parsed["values"] as? [Double] {
                
                return ChartData(labels: labels, values: values, type: chartType)
            }
            
        } catch {
            print("Chart generation error: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    private func getLanguageName(_ code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forIdentifier: code) ?? code
    }
    
    private func parseSpeechAnalysis(_ response: String) -> SpeechAnalysisResult {
        var sentiment = "neutral"
        var keyTopics: [String] = []
        var actionItems: [String] = []
        var speakingPattern = SpeakingPattern.neutral
        var confidence: Double = 0.0
        var suggestions: [String] = []
        
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            if line.starts(with: "SENTIMENT:") {
                sentiment = line.replacingOccurrences(of: "SENTIMENT:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.starts(with: "KEY_TOPICS:") {
                let topicsString = line.replacingOccurrences(of: "KEY_TOPICS:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                keyTopics = topicsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else if line.starts(with: "ACTION_ITEMS:") {
                let itemsString = line.replacingOccurrences(of: "ACTION_ITEMS:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                actionItems = itemsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else if line.starts(with: "SPEAKING_PATTERN:") {
                let patternString = line.replacingOccurrences(of: "SPEAKING_PATTERN:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                speakingPattern = SpeakingPattern(rawValue: patternString) ?? .neutral
            } else if line.starts(with: "CONFIDENCE_SCORE:") {
                let scoreString = line.replacingOccurrences(of: "CONFIDENCE_SCORE:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                confidence = Double(scoreString) ?? 0.0
            } else if line.starts(with: "SUGGESTIONS:") {
                let suggestionsString = line.replacingOccurrences(of: "SUGGESTIONS:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                suggestions = suggestionsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
        }
        
        return SpeechAnalysisResult(
            sentiment: sentiment,
            keyTopics: keyTopics,
            actionItems: actionItems,
            speakingPattern: speakingPattern,
            confidence: confidence,
            suggestions: suggestions
        )
    }
}

// MARK: - Supporting Types
enum TextEnhancementStyle {
    case academic
    case casual
    case professional
    case creative
    
    var instructions: String {
        switch self {
        case .academic:
            return "Enhance text for academic writing with formal tone, proper citations, and scholarly language."
        case .casual:
            return "Make text more conversational and easy to read while maintaining clarity."
        case .professional:
            return "Enhance text for professional communication with clear, concise, and authoritative tone."
        case .creative:
            return "Add creative flair while maintaining the core message and making it engaging."
        }
    }
    
    var description: String {
        switch self {
        case .academic: return "Academic Style"
        case .casual: return "Casual Style"
        case .professional: return "Professional Style"
        case .creative: return "Creative Style"
        }
    }
}

enum ContentFormat {
    case outline
    case mindMap
    case summary
    case flashcards
    case timeline
    
    var description: String {
        switch self {
        case .outline: return "structured outline with headers and bullet points"
        case .mindMap: return "mind map format with central topic and branches"
        case .summary: return "concise summary with key points"
        case .flashcards: return "question and answer flashcard format"
        case .timeline: return "chronological timeline format"
        }
    }
}

enum ChartType: String, CaseIterable {
    case bar = "bar chart"
    case line = "line chart"
    case pie = "pie chart"
    case scatter = "scatter plot"
}

enum SpeakingPattern: String, CaseIterable {
    case confident = "confident"
    case hesitant = "hesitant"
    case neutral = "neutral"
    case excited = "excited"
    case rushed = "rushed"
    case clear = "clear"
}

struct SpeechAnalysisResult {
    let sentiment: String
    let keyTopics: [String]
    let actionItems: [String]
    let speakingPattern: SpeakingPattern
    let confidence: Double
    let suggestions: [String]
}

struct TranslationResult {
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let confidence: Double
}

struct HandwritingAnalysisResult {
    let recognizedText: String
    let confidence: Double
    let hasIssues: Bool
    let suggestions: [String]
    let enhancedText: String
}

struct ChartData {
    let labels: [String]
    let values: [Double]
    let type: ChartType
}











/*
 import SwiftUI
 import Foundation
 import FoundationModels
 internal import Combine
 internal import UniformTypeIdentifiers








 @MainActor
 class AIService: ObservableObject {
     // MARK: - Published Properties
     @Published var isProcessing = false
     @Published var streamingResponse = ""
     @Published var processingProgress: Double = 0.0
     var modelAvailability: SystemLanguageModel.Availability
     
     // MARK: - Private Properties
     private let systemModel = SystemLanguageModel.default
     private var currentSession: LanguageModelSession?
     
     // MARK: - Initialization
     init() {
         self.modelAvailability = systemModel.availability
     }
     
     // MARK: - Model Availability Check
     func checkModelAvailability() -> Bool {
         modelAvailability = systemModel.availability
         return modelAvailability == .available
     }
     
     func getUnavailabilityReason() -> SystemLanguageModel.Availability.UnavailableReason? {
         if case .unavailable(let reason) = modelAvailability {
             return reason
         }
         return nil
     }
     
     // MARK: - Session Management
     private func createSession(with instructions: String? = nil) -> LanguageModelSession {
         if let instructions = instructions {
             return LanguageModelSession(instructions: Instructions(instructions))
         } else {
             return LanguageModelSession()
         }
     }
     
     // MARK: - Text Processing
     func proofreadText(_ text: String) async -> AIProcessingResult {
         guard checkModelAvailability() else {
             return AIProcessingResult(
                 summary: "AI model unavailable",
                 keyPoints: [],
                 suggestions: [],
                 mistakes: []
             )
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         do {
             let instructions = """
             You are a professional proofreader and writing assistant. Analyze the given text for:
             1. Grammar and spelling errors
             2. Clarity and readability issues
             3. Style improvements
             4. Tone consistency
             
             Provide specific, actionable feedback.
             """
             
             let session = createSession(with: instructions)
             
             let prompt = """
             Please proofread and analyze this text:
             
             \(text)
             
             Provide:
             1. A brief summary of the text quality
             2. Key areas for improvement
             3. Specific suggestions for enhancement
             4. Any grammar or spelling mistakes found
             """
             
             let response = try await session.respond(to: Prompt(prompt))
             
             // Parse the response to extract structured feedback
             let mistakes = extractMistakes(from: response.content, originalText: text)
             let suggestions = extractSuggestions(from: response.content)
             
             return AIProcessingResult(
                 summary: "Text analysis completed successfully",
                 keyPoints: ["Grammar check complete", "Style analysis provided"],
                 suggestions: suggestions,
                 mistakes: mistakes
             )
             
         } catch {
             print("Proofreading error: \(error)")
             return AIProcessingResult(
                 summary: "Error during proofreading: \(error.localizedDescription)",
                 keyPoints: [],
                 suggestions: [],
                 mistakes: []
             )
         }
     }
     
     func summarizeText(_ text: String) async -> String {
         guard checkModelAvailability() else {
             return "AI model unavailable for summarization"
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         do {
             let instructions = """
             You are an expert at creating concise, informative summaries.
             Create summaries that capture the key points and main ideas while being easy to understand.
             """
             
             let session = createSession(with: instructions)
             
             let prompt = """
             Please create a concise summary of the following text.
             Focus on the main ideas and key points:
             
             \(text)
             """
             
             let response = try await session.respond(to: Prompt(prompt))
             return response.content
             
         } catch {
             print("Summarization error: \(error)")
             return "Error creating summary: \(error.localizedDescription)"
         }
     }
     
     func explainText(_ text: String, level: ExplanationLevel) async -> String {
         guard checkModelAvailability() else {
             return "AI model unavailable for explanation"
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         do {
             let levelInstruction = switch level {
             case .elementary:
                 "Explain this in simple terms suitable for a middle school student. Use everyday language and basic concepts."
             case .intermediate:
                 "Provide a clear explanation suitable for a high school or early college student. Include some technical detail."
             case .advanced:
                 "Give a comprehensive explanation with technical depth suitable for advanced students or professionals."
             }
             
             let instructions = """
             You are an educational expert who excels at explaining complex topics.
             \(levelInstruction)
             Use clear examples and analogies where helpful.
             """
             
             let session = createSession(with: instructions)
             
             let prompt = """
             Please explain the following text:
             
             \(text)
             """
             
             let response = try await session.respond(to: Prompt(prompt))
             return response.content
             
         } catch {
             print("Explanation error: \(error)")
             return "Error creating explanation: \(error.localizedDescription)"
         }
     }
     
     func extractKeyPoints(from text: String) async -> [String] {
         guard checkModelAvailability() else {
             return ["AI model unavailable"]
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         do {
             let instructions = """
             You are expert at identifying key points and main ideas in text.
             Extract the most important points as a bulleted list.
             Each point should be concise and capture a core idea.
             """
             
             let session = createSession(with: instructions)
             
             let prompt = """
             Extract the key points from this text as a bulleted list:
             
             \(text)
             
             Format each point as:
             • [key point]
             """
             
             let response = try await session.respond(to: Prompt(prompt))
             
             // Parse the bulleted response
             let keyPoints = response.content
                 .components(separatedBy: .newlines)
                 .compactMap { line in
                     let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                     if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                         return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
                     }
                     return nil
                 }
             
             return keyPoints.isEmpty ? [response.content] : keyPoints
             
         } catch {
             print("Key points extraction error: \(error)")
             return ["Error extracting key points: \(error.localizedDescription)"]
         }
     }
     
     // MARK: - Quiz Generation
     func generateQuiz(from note: Note, questionCount: Int = 5) async -> Quiz {
         guard checkModelAvailability() else {
             return Quiz(
                 title: "Quiz generation unavailable",
                 questions: [],
                 sourceNoteId: note.id
             )
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         do {
             let instructions = """
             You are an expert educator who creates engaging and educational quizzes.
             Create diverse question types that test understanding, not just memorization.
             Include clear, unambiguous questions with plausible distractors for multiple choice.
             """
             
             let session = createSession(with: instructions)
             
             let prompt = """
             Create a quiz with \(questionCount) questions based on this content:
             
             \(note.content)
             
             Include a mix of:
             - Multiple choice questions (4 options each)
             - True/false questions
             - Short answer questions
             
             For each question, provide:
             1. The question text
             2. The question type
             3. Answer options (for multiple choice)
             4. The correct answer
             5. A brief explanation of why the answer is correct
             
             Format each question clearly and number them.
             """
             
             let response = try await session.respond(to: Prompt(prompt))
             
             // Parse the response to create quiz questions
             let questions = parseQuizQuestions(from: response.content)
             
             return Quiz(
                 title: "Quiz: \(note.title)",
                 questions: questions,
                 sourceNoteId: note.id
             )
             
         } catch {
             print("Quiz generation error: \(error)")
             return Quiz(
                 title: "Error generating quiz",
                 questions: [],
                 sourceNoteId: note.id
             )
         }
     }
     
     // MARK: - Voice Transcription
     func transcribeAudio(_ audioData: Data) async -> String {
         guard checkModelAvailability() else {
             return "AI model unavailable for transcription"
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         // Note: Actual audio transcription would require Speech framework
         // This is a placeholder implementation
         do {
             try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate processing time
             return "Transcribed audio content would appear here. This requires Speech framework integration."
         } catch {
             return "Error during transcription simulation"
         }
     }
     
     func translateText(_ text: String, from sourceLanguage: String, to targetLanguage: String) async -> TranslatedContent {
         guard checkModelAvailability() else {
             return TranslatedContent(
                 originalLanguage: sourceLanguage,
                 targetLanguage: targetLanguage,
                 translatedText: "Translation unavailable"
             )
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         do {
             let instructions = """
             You are a professional translator with expertise in multiple languages.
             Provide accurate, contextually appropriate translations that preserve the original meaning and tone.
             """
             
             let session = createSession(with: instructions)
             
             let prompt = """
             Translate the following text from \(sourceLanguage) to \(targetLanguage):
             
             \(text)
             
             Provide only the translation without additional commentary.
             """
             
             let response = try await session.respond(to: Prompt(prompt))
             
             return TranslatedContent(
                 originalLanguage: sourceLanguage,
                 targetLanguage: targetLanguage,
                 translatedText: response.content
             )
             
         } catch {
             print("Translation error: \(error)")
             return TranslatedContent(
                 originalLanguage: sourceLanguage,
                 targetLanguage: targetLanguage,
                 translatedText: "Error during translation: \(error.localizedDescription)"
             )
         }
     }
     
     // MARK: - Handwriting Recognition
     func recognizeHandwriting(from imageData: Data) async -> (text: String, smudgeDetected: Bool) {
         guard checkModelAvailability() else {
             return ("Handwriting recognition unavailable", false)
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         // Note: This would require Vision framework for actual OCR
         // This is a placeholder implementation
         do {
             try await Task.sleep(nanoseconds: 1_500_000_000)
             return ("Recognized handwritten text would appear here. This requires Vision framework integration.", Bool.random())
         } catch {
             return ("Error during handwriting recognition", false)
         }
     }
     
     // MARK: - Document Processing
     func generateNotesFromDocument(_ documentData: Data, fileType: UTType) async -> Note {
         guard checkModelAvailability() else {
             return Note(
                 title: "Document processing unavailable",
                 content: "AI model not available for document processing"
             )
         }
         
         isProcessing = true
         defer { isProcessing = false }
         
         do {
             // Extract text from document (would need proper document parsing)
             let extractedText = "Document content extraction would happen here using appropriate parsers"
             
             let instructions = """
             You are an expert at analyzing documents and creating well-structured study notes.
             Create comprehensive notes that organize the information clearly with headings, key points, and summaries.
             """
             
             let session = createSession(with: instructions)
             
             let prompt = """
             Create detailed study notes from this document content:
             
             \(extractedText)
             
             Structure the notes with:
             1. A clear title
             2. Main topics as headings
             3. Key points under each topic
             4. Important concepts highlighted
             5. A summary section
             
             Use markdown formatting for better organization.
             """
             
             let response = try await session.respond(to: Prompt(prompt))
             
             var note = Note(
                 title: "Notes from Document",
                 content: response.content
             )
             
             // Generate AI insights
             note.aiSummary = await summarizeText(response.content)
             note.aiKeyPoints = await extractKeyPoints(from: response.content)
             
             return note
             
         } catch {
             print("Document processing error: \(error)")
             return Note(
                 title: "Error processing document",
                 content: "Error: \(error.localizedDescription)"
             )
         }
     }
     
     // MARK: - Streaming Responses
     func streamResponse(for prompt: String, instructions: String? = nil) async {
         guard checkModelAvailability() else {
             streamingResponse = "AI model unavailable for streaming"
             return
         }
         
         isProcessing = true
         streamingResponse = ""
         
         do {
             let session = createSession(with: instructions)
             let stream = session.streamResponse(to: Prompt(prompt))
             
             for try await partialResult in stream {
                 streamingResponse = partialResult
             }
             
         } catch {
             streamingResponse = "Error during streaming: \(error.localizedDescription)"
         }
         
         isProcessing = false
     }
     
     // MARK: - Advanced AI Features
     func analyzeVoiceTranscript(_ transcript: String) async -> VoiceAnalysisResult {
         guard checkModelAvailability() else {
             return VoiceAnalysisResult(
                 sentiment: "unavailable",
                 topics: [],
                 actionItems: [],
                 confidence: 0.0
             )
         }
         
         do {
             let instructions = """
             You are an expert at analyzing voice transcripts and extracting meaningful insights.
             Analyze the transcript for sentiment, main topics, and actionable items.
             """
             
             let session = createSession(with: instructions)
             
             let prompt = """
             Analyze this voice transcript:
             
             \(transcript)
             
             Provide:
             1. Overall sentiment (positive/negative/neutral)
             2. Main topics discussed
             3. Any action items or tasks mentioned
             4. Key insights
             """
             
             let response = try await session.respond(to: Prompt(prompt))
             
             return parseVoiceAnalysis(from: response.content)
             
         } catch {
             return VoiceAnalysisResult(
                 sentiment: "error",
                 topics: [],
                 actionItems: [],
                 confidence: 0.0
             )
         }
     }
     
     // MARK: - Helper Methods
     private func extractMistakes(from response: String, originalText: String) -> [WritingMistake] {
         // Parse the AI response to extract specific mistakes
         // This would need more sophisticated parsing in a real implementation
         var mistakes: [WritingMistake] = []
         
         // Look for common patterns in the response
         let lines = response.components(separatedBy: .newlines)
         for line in lines {
             if line.lowercased().contains("grammar") || line.lowercased().contains("spelling") {
                 // Create a placeholder mistake
                 mistakes.append(WritingMistake(
                     type: .grammar,
                     location: NSRange(location: 0, length: 10),
                     description: line.trimmingCharacters(in: .whitespacesAndNewlines),
                     suggestion: "See AI feedback for details"
                 ))
             }
         }
         
         return mistakes
     }
     
     private func extractSuggestions(from response: String) -> [String] {
         // Extract suggestions from the AI response
         let lines = response.components(separatedBy: .newlines)
         return lines
             .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
             .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
             .prefix(5)
             .map { String($0) }
     }
     
     private func parseQuizQuestions(from response: String) -> [QuizQuestion] {
         // Parse the AI response to create quiz questions
         // This is a simplified implementation
         var questions: [QuizQuestion] = []
         
         let lines = response.components(separatedBy: .newlines)
         var currentQuestion: String?
         var options: [String] = []
         var correctAnswer: String = ""
         
         for line in lines {
             let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
             
             if trimmed.hasPrefix("1.") || trimmed.hasPrefix("2.") || trimmed.hasPrefix("3.") {
                 // Save previous question if exists
                 if let question = currentQuestion {
                     questions.append(QuizQuestion(
                         question: question,
                         type: options.isEmpty ? .trueFalse : .multipleChoice,
                         options: options,
                         correctAnswer: correctAnswer.isEmpty ? "True" : correctAnswer,
                         explanation: "Based on the provided content"
                     ))
                 }
                 
                 // Start new question
                 currentQuestion = trimmed
                 options = []
                 correctAnswer = ""
             }
         }
         
         // Add the last question
         if let question = currentQuestion {
             questions.append(QuizQuestion(
                 question: question,
                 type: options.isEmpty ? .trueFalse : .multipleChoice,
                 options: options,
                 correctAnswer: correctAnswer.isEmpty ? "True" : correctAnswer,
                 explanation: "Based on the provided content"
             ))
         }
         
         // If no questions were parsed, create some default ones
         if questions.isEmpty {
             questions = [
                 QuizQuestion(
                     question: "What is the main topic of this content?",
                     type: .shortAnswer,
                     options: [],
                     correctAnswer: "See notes for details",
                     explanation: "Review the main content"
                 )
             ]
         }
         
         return questions
     }
     
     private func parseVoiceAnalysis(from response: String) -> VoiceAnalysisResult {
         // Parse the AI response to create voice analysis
         // This is a simplified implementation
         return VoiceAnalysisResult(
             sentiment: "neutral",
             topics: ["General discussion"],
             actionItems: [],
             confidence: 0.85
         )
     }
 }

 // MARK: - Supporting Types
 enum ExplanationLevel: String, CaseIterable {
     case elementary = "Elementary"
     case intermediate = "Intermediate"
     case advanced = "Advanced"
 }

 struct VoiceAnalysisResult {
     let sentiment: String
     let topics: [String]
     let actionItems: [String]
     let confidence: Double
 }
 */
//
//  AIService.swift
//  StudyBuddy
//
//  Enhanced AI Service with Foundation Models, Speech Analysis, and Translation
//
