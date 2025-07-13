//
//  Note.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
import Foundation
internal import UniformTypeIdentifiers


// MARK: - Note Model
struct Note: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var tags: [String]
    var attachments: [Attachment]
    var voiceNotes: [VoiceNote]
    var handwrittenImages: [HandwrittenNote]
    var aiSummary: String?
    var aiKeyPoints: [String]
    
    init(title: String = "Untitled Note", content: String = "") {
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.tags = []
        self.attachments = []
        self.voiceNotes = []
        self.handwrittenImages = []
        self.aiKeyPoints = []
    }
}

// MARK: - Attachment Model
struct Attachment: Identifiable, Codable, Hashable {
    var id = UUID()
    var fileName: String
    var fileType: UTType
    var data: Data
    var thumbnail: Data?
    
    init(fileName: String, fileType: UTType, data: Data) {
        self.fileName = fileName
        self.fileType = fileType
        self.data = data
    }
}

// MARK: - Voice Note Model
struct VoiceNote: Identifiable, Codable, Hashable {
    var id = UUID()
    var audioData: Data
    var duration: TimeInterval
    var transcript: String?
    var translatedTranscript: TranslatedContent?
    var createdAt: Date
    
    init(audioData: Data, duration: TimeInterval) {
        self.audioData = audioData
        self.duration = duration
        self.createdAt = Date()
    }
}

// MARK: - Translated Content
struct TranslatedContent: Codable, Hashable {
    var originalLanguage: String
    var targetLanguage: String
    var translatedText: String
}

// MARK: - Handwritten Note Model
struct HandwrittenNote: Identifiable, Codable, Hashable {
    var id = UUID()
    var imageData: Data?
    var recognizedText: String?
    var smudgeDetected: Bool = false
    var enhancedImageData: Data?
    
    init(imageData: Data) {
        self.imageData = imageData
    }
}

// MARK: - Quiz Models
struct Quiz: Identifiable, Codable {
    var id = UUID()
    var title: String
    var questions: [QuizQuestion]
    var sourceNoteId: UUID
    var createdAt: Date
    
    init(title: String, questions: [QuizQuestion], sourceNoteId: UUID) {
        self.title = title
        self.questions = questions
        self.sourceNoteId = sourceNoteId
        self.createdAt = Date()
    }
}

struct QuizQuestion: Identifiable, Codable {
    var id = UUID()
    var question: String
    var type: QuestionType
    var options: [String]
    var correctAnswer: String
    var explanation: String?
    
    enum QuestionType: String, Codable, CaseIterable {
        case multipleChoice = "Multiple Choice"
        case trueFalse = "True/False"
        case shortAnswer = "Short Answer"
        case fillInBlank = "Fill in the Blank"
    }
}

// MARK: - AI Processing Result
struct AIProcessingResult: Codable {
    var summary: String
    var keyPoints: [String]
    var suggestions: [String]
    var mistakes: [WritingMistake]
}

struct WritingMistake: Codable, Identifiable {
    var id = UUID()
    var type: MistakeType
    var location: NSRange
    var description: String
    var suggestion: String
    
    enum MistakeType: String, Codable {
        case grammar
        case spelling
        case clarity
        case conciseness
        case factual
    }
}
