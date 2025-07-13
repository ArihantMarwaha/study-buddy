//
//  NotesManager.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//
import SwiftUI
internal import Combine
internal import UniformTypeIdentifiers
import Foundation

@MainActor
class NotesManager: ObservableObject {
    // MARK: - Published Properties
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?
    @Published var searchText = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - AI Integration
    var aiService: AIService?
    
    // MARK: - Study Features
    @Published var studyMode = false
    @Published var currentQuiz: Quiz?
    @Published var studySession: StudySession?
    @Published var studySessions: [StudySession] = []
    
    // MARK: - Note Templates
    @Published var noteTemplates: [NoteTemplate] = []
    
    // MARK: - Private Properties
    private var autosaveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var debouncedSaveWorkItem: DispatchWorkItem?
    private let userDefaults = UserDefaults.standard
    private let notesKey = "StudyBuddy.SavedNotes"
    private let studySessionsKey = "StudyBuddy.StudySessions"
    private let templatesKey = "StudyBuddy.NoteTemplates"
    
    // MARK: - Initialization
    init() {
        loadNotes()
        loadStudySessions()
        loadNoteTemplates()
        setupAutosave()
        setupObservers()
        createDefaultTemplates()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Auto-select first note when notes change
        $notes
            .sink { [weak self] notes in
                if self?.selectedNote == nil && !notes.isEmpty {
                    self?.selectedNote = notes.first
                }
            }
            .store(in: &cancellables)
    }
    
    func setAIService(_ aiService: AIService) {
        self.aiService = aiService
    }
    
    func selectNote(_ note: Note) {
        selectedNote = note
    }
    
    // MARK: - Note CRUD Operations
    func createNewNote(from template: NoteTemplate? = nil) -> Note {
        var newNote: Note
        
        if let template = template {
            newNote = Note(title: template.title, content: template.content)
            newNote.tags = template.tags
        } else {
            newNote = Note()
        }
        
        notes.insert(newNote, at: 0)
        selectedNote = newNote
        saveNotes()
        
        // Create initial study session if in study mode
        if studyMode {
            startStudySession(for: newNote)
        }
        
        successMessage = "Note created successfully"
        return newNote
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = notes.first
        }
        
        // Clean up related study sessions
        removeStudySession(for: note.id)
        
        saveNotes()
        successMessage = "Note deleted successfully"
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.modifiedAt = Date()
            notes[index] = updatedNote
            
            if selectedNote?.id == note.id {
                selectedNote = updatedNote
            }
            
            // Update study session if active
            updateStudySession(for: updatedNote)
            
            // Debounced save
            debouncedSaveWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.saveNotes()
            }
            debouncedSaveWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }
    
    func duplicateNote(_ note: Note) -> Note {
        var duplicatedNote = note
        duplicatedNote.id = UUID()
        duplicatedNote.title = "\(note.title) (Copy)"
        duplicatedNote.createdAt = Date()
        duplicatedNote.modifiedAt = Date()
        
        notes.insert(duplicatedNote, at: notes.firstIndex(where: { $0.id == note.id }) ?? 0)
        selectedNote = duplicatedNote
        saveNotes()
        
        successMessage = "Note duplicated successfully"
        return duplicatedNote
    }
    
    // MARK: - Search and Filter
    var filteredNotes: [Note] {
        let filtered = notes.filter { note in
            if searchText.isEmpty {
                return true
            }
            
            let searchLower = searchText.lowercased()
            return note.title.lowercased().contains(searchLower) ||
                   note.content.lowercased().contains(searchLower) ||
                   note.tags.contains { $0.lowercased().contains(searchLower) } ||
                   (note.aiSummary?.lowercased().contains(searchLower) ?? false) ||
                   note.aiKeyPoints.contains { $0.lowercased().contains(searchLower) }
        }
        
        return filtered.sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    var notesByCategory: [String: [Note]] {
        Dictionary(grouping: notes) { note in
            note.tags.first ?? "Uncategorized"
        }
    }
    
    var recentNotes: [Note] {
        notes.sorted { $0.modifiedAt > $1.modifiedAt }.prefix(5).map { $0 }
    }
    
    // MARK: - AI-Enhanced Operations
    func enhanceNoteWithAI(_ note: Note) async {
        guard let aiService = aiService else {
            errorMessage = "AI service not available"
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Generate summary and key points concurrently
            async let summary = aiService.summarizeText(note.content)
            async let keyPoints = aiService.extractKeyPoints(from: note.content)
            
            var enhancedNote = note
            enhancedNote.aiSummary = await summary
            enhancedNote.aiKeyPoints = await keyPoints
            
            updateNote(enhancedNote)
            successMessage = "Note enhanced with AI insights"
            
        } catch {
            errorMessage = "Failed to enhance note: \(error.localizedDescription)"
        }
    }
    
    func generateQuizFromNote(_ note: Note, questionCount: Int = 5) async -> Quiz? {
        guard let aiService = aiService else {
            errorMessage = "AI service not available"
            return nil
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let quiz = await aiService.generateQuiz(from: note, questionCount: questionCount)
            currentQuiz = quiz
            successMessage = "Quiz generated successfully"
            return quiz
            
        } catch {
            errorMessage = "Failed to generate quiz: \(error.localizedDescription)"
            return nil
        }
    }
    
    func improveNoteContent(_ note: Note) async {
        guard let aiService = aiService else {
            errorMessage = "AI service not available"
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let analysis = await aiService.proofreadText(note.content)
            
            // Apply suggestions if available
            var improvedNote = note
            if !analysis.suggestions.isEmpty {
                improvedNote.content += "\n\n## AI Suggestions:\n"
                for suggestion in analysis.suggestions {
                    improvedNote.content += "• \(suggestion)\n"
                }
            }
            
            updateNote(improvedNote)
            successMessage = "Note content improved with AI suggestions"
            
        } catch {
            errorMessage = "Failed to improve note: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Voice Notes Management
    func addVoiceNote(to note: Note, audioData: Data, duration: TimeInterval) async {
        guard audioData.count < 10_000_000 else { // 10MB limit
            errorMessage = "Audio recording too large. Maximum size is 10MB."
            return
        }
        
        var voiceNote = VoiceNote(audioData: audioData, duration: duration)
        
        // Generate transcript if AI service is available
        if let aiService = aiService {
            isProcessing = true
            voiceNote.transcript = await aiService.transcribeAudio(audioData)
            isProcessing = false
        }
        
        var updatedNote = note
        updatedNote.voiceNotes.append(voiceNote)
        updateNote(updatedNote)
        
        successMessage = "Voice note added successfully"
    }
    
    func analyzeVoiceNotes(for note: Note) async -> VoiceAnalysisResult? {
        guard let aiService = aiService else {
            errorMessage = "AI service not available"
            return nil
        }
        
        let allTranscripts = note.voiceNotes.compactMap { $0.transcript }.joined(separator: "\n\n")
        guard !allTranscripts.isEmpty else {
            errorMessage = "No transcripts available for analysis"
            return nil
        }
        
        isProcessing = true
        let analysis = await aiService.analyzeVoiceTranscript(allTranscripts)
        isProcessing = false
        
        return analysis
    }
    
    // MARK: - Handwritten Notes Management
    func addHandwrittenNote(to note: Note, imageData: Data) async {
        guard imageData.count < 10_000_000 else { // 10MB limit
            errorMessage = "Image too large. Maximum size is 10MB."
            return
        }
        
        var handwrittenNote = HandwrittenNote(imageData: imageData)
        
        // Process with AI if available
        if let aiService = aiService {
            isProcessing = true
            let (recognizedText, smudgeDetected) = await aiService.recognizeHandwriting(from: imageData)
            handwrittenNote.recognizedText = recognizedText
            handwrittenNote.smudgeDetected = smudgeDetected
            isProcessing = false
        }
        
        var updatedNote = note
        updatedNote.handwrittenImages.append(handwrittenNote)
        updateNote(updatedNote)
        
        successMessage = "Handwritten note added and processed"
    }
    
    // MARK: - Document Processing
    func generateNotesFromDocument(_ data: Data, fileName: String, fileType: UTType) async -> Note? {
        guard let aiService = aiService else {
            errorMessage = "AI service not available"
            return nil
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let generatedNote = await aiService.generateNotesFromDocument(data, fileType: fileType)
            var finalNote = generatedNote
            finalNote.title = "Notes from \(fileName)"
            
            notes.insert(finalNote, at: 0)
            selectedNote = finalNote
            saveNotes()
            
            successMessage = "Notes generated from document successfully"
            return finalNote
            
        } catch {
            errorMessage = "Failed to generate notes from document: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Study Sessions
    func startStudySession(for note: Note) {
        let session = StudySession(
            noteId: note.id,
            startTime: Date(),
            targetDuration: TimeInterval(60 * 60) // 1 hour default
        )
        
        studySessions.append(session)
        studySession = session
        saveStudySessions()
        
        successMessage = "Study session started"
    }
    
    func endCurrentStudySession() {
        guard var session = studySession else { return }
        
        session.endTime = Date()
        session.actualDuration = session.endTime!.timeIntervalSince(session.startTime)
        
        // Update in array
        if let index = studySessions.firstIndex(where: { $0.id == session.id }) {
            studySessions[index] = session
        }
        
        studySession = nil
        saveStudySessions()
        
        successMessage = "Study session completed"
    }
    
    func updateStudySession(for note: Note) {
        guard var session = studySession, session.noteId == note.id else { return }
        
        session.lastActivity = Date()
        if let index = studySessions.firstIndex(where: { $0.id == session.id }) {
            studySessions[index] = session
        }
        studySession = session
    }
    
    func removeStudySession(for noteId: UUID) {
        studySessions.removeAll { $0.noteId == noteId }
        if studySession?.noteId == noteId {
            studySession = nil
        }
        saveStudySessions()
    }
    
    // MARK: - Note Templates
    private func createDefaultTemplates() {
        guard noteTemplates.isEmpty else { return }
        
        noteTemplates = [
            NoteTemplate(
                title: "Lecture Notes",
                content: """
                # Lecture: [Title]
                **Date:** [Date]
                **Course:** [Course Name]
                **Professor:** [Name]
                
                ## Key Topics
                - 
                
                ## Main Points
                1. 
                
                ## Questions
                - 
                
                ## Action Items
                - 
                """,
                tags: ["lecture", "notes"]
            ),
            NoteTemplate(
                title: "Research Notes",
                content: """
                # Research: [Topic]
                **Source:** [Citation]
                **Date:** [Date]
                
                ## Hypothesis/Question
                
                ## Key Findings
                - 
                
                ## Methodology
                
                ## Conclusions
                
                ## Further Reading
                - 
                """,
                tags: ["research", "academic"]
            ),
            NoteTemplate(
                title: "Meeting Notes",
                content: """
                # Meeting: [Title]
                **Date:** [Date]
                **Attendees:** [Names]
                
                ## Agenda
                1. 
                
                ## Discussion Points
                - 
                
                ## Decisions Made
                - 
                
                ## Action Items
                - [ ] 
                
                ## Next Steps
                - 
                """,
                tags: ["meeting", "work"]
            ),
            NoteTemplate(
                title: "Book Summary",
                content: """
                # Book: [Title]
                **Author:** [Author Name]
                **Genre:** [Genre]
                **Rating:** ⭐⭐⭐⭐⭐
                
                ## Summary
                
                ## Key Themes
                - 
                
                ## Favorite Quotes
                > 
                
                ## Personal Thoughts
                
                ## Recommended For
                - 
                """,
                tags: ["book", "summary", "reading"]
            )
        ]
        
        saveNoteTemplates()
    }
    
    // MARK: - Export Functions
    func exportNote(_ note: Note, format: ExportFormat) -> Data? {
        switch format {
        case .markdown:
            return exportAsMarkdown(note)
        case .pdf:
            return exportAsPDF(note)
        case .plainText:
            return note.content.data(using: .utf8)
        case .rtf:
            return exportAsRTF(note)
        case .json:
            return exportAsJSON(note)
        }
    }
    
    private func exportAsMarkdown(_ note: Note) -> Data? {
        var markdown = "# \(note.title)\n\n"
        markdown += "*Created: \(note.createdAt.formatted())*\n"
        markdown += "*Modified: \(note.modifiedAt.formatted())*\n\n"
        
        if !note.tags.isEmpty {
            markdown += "**Tags:** \(note.tags.joined(separator: ", "))\n\n"
        }
        
        if let summary = note.aiSummary {
            markdown += "## AI Summary\n\(summary)\n\n"
        }
        
        if !note.aiKeyPoints.isEmpty {
            markdown += "## Key Points\n"
            note.aiKeyPoints.forEach { point in
                markdown += "- \(point)\n"
            }
            markdown += "\n"
        }
        
        markdown += "## Content\n\(note.content)\n"
        
        // Add voice note transcripts
        if !note.voiceNotes.isEmpty {
            markdown += "\n## Voice Notes\n"
            for (index, voiceNote) in note.voiceNotes.enumerated() {
                markdown += "### Voice Note \(index + 1)\n"
                markdown += "Duration: \(formatDuration(voiceNote.duration))\n"
                if let transcript = voiceNote.transcript {
                    markdown += "Transcript: \(transcript)\n"
                }
                markdown += "\n"
            }
        }
        
        // Add handwritten note text
        if !note.handwrittenImages.isEmpty {
            markdown += "\n## Handwritten Notes\n"
            for (index, handwritten) in note.handwrittenImages.enumerated() {
                if let text = handwritten.recognizedText {
                    markdown += "### Handwritten Note \(index + 1)\n"
                    markdown += "\(text)\n\n"
                }
            }
        }
        
        return markdown.data(using: .utf8)
    }
    
    private func exportAsPDF(_ note: Note) -> Data? {
        // PDF export implementation would go here
        // Using NSPrintOperation or PDFKit
        return nil
    }
    
    private func exportAsRTF(_ note: Note) -> Data? {
        let attributedString = NSAttributedString(string: note.content)
        return try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
    
    private func exportAsJSON(_ note: Note) -> Data? {
        do {
            return try JSONEncoder().encode(note)
        } catch {
            errorMessage = "Failed to encode note as JSON"
            return nil
        }
    }
    
    // MARK: - Persistence
    func saveNotes() {
        do {
            let encoded = try JSONEncoder().encode(notes)
            userDefaults.set(encoded, forKey: notesKey)
        } catch {
            errorMessage = "Failed to save notes: \(error.localizedDescription)"
        }
    }
    
    private func loadNotes() {
        guard let data = userDefaults.data(forKey: notesKey) else {
            createWelcomeNote()
            return
        }
        
        do {
            notes = try JSONDecoder().decode([Note].self, from: data)
            selectedNote = notes.first
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
            createWelcomeNote()
        }
    }
    
    private func saveStudySessions() {
        do {
            let encoded = try JSONEncoder().encode(studySessions)
            userDefaults.set(encoded, forKey: studySessionsKey)
        } catch {
            errorMessage = "Failed to save study sessions: \(error.localizedDescription)"
        }
    }
    
    private func loadStudySessions() {
        guard let data = userDefaults.data(forKey: studySessionsKey) else { return }
        
        do {
            studySessions = try JSONDecoder().decode([StudySession].self, from: data)
        } catch {
            errorMessage = "Failed to load study sessions: \(error.localizedDescription)"
        }
    }
    
    private func saveNoteTemplates() {
        do {
            let encoded = try JSONEncoder().encode(noteTemplates)
            userDefaults.set(encoded, forKey: templatesKey)
        } catch {
            errorMessage = "Failed to save note templates: \(error.localizedDescription)"
        }
    }
    
    private func loadNoteTemplates() {
        guard let data = userDefaults.data(forKey: templatesKey) else { return }
        
        do {
            noteTemplates = try JSONDecoder().decode([NoteTemplate].self, from: data)
        } catch {
            errorMessage = "Failed to load note templates: \(error.localizedDescription)"
        }
    }
    
    private func createWelcomeNote() {
        let welcomeNote = Note(
            title: "Welcome to Study Buddy! 🎓",
            content: """
            # Welcome to Study Buddy!
            
            Your AI-powered study companion is ready to help you succeed. Here's what you can do:
            
            ## 📝 Notes Features
            - **AI-Powered Writing**: Click the brain icon to proofread, summarize, or explain your notes
            - **Voice Notes**: Record audio notes and get automatic transcriptions
            - **Handwriting Import**: Import photos of handwritten notes with text recognition
            - **Smart Organization**: Tag and search your notes easily
            
            ## 🚀 Getting Started
            1. Create a new note with ⌘N
            2. Try the AI features in the toolbar
            3. Attach files, images, or voice recordings
            4. Generate quizzes from your notes
            
            ## 💡 Pro Tips
            - Use markdown formatting for better organization
            - The AI can help you find mistakes and improve clarity
            - Export your notes in multiple formats
            - Try the note templates for structured content
            
            ## 📊 Study Features
            - Start study sessions to track your learning time
            - Generate quizzes from your notes for self-testing
            - Use voice analysis to understand your speaking patterns
            
            Happy studying! 📚
            """
        )
        notes = [welcomeNote]
        selectedNote = welcomeNote
        saveNotes()
    }
    
    private func setupAutosave() {
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                self.saveNotes()
            }
        }
    }
    
    // MARK: - Utility Functions
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    deinit {
        autosaveTimer?.invalidate()
    }
}

// MARK: - Supporting Models
struct NoteTemplate: Identifiable, Codable {
    var id = UUID()
    let title: String
    let content: String
    let tags: [String]
}

struct StudySession: Identifiable, Codable {
    var id = UUID()
    let noteId: UUID
    let startTime: Date
    var endTime: Date?
    let targetDuration: TimeInterval
    var actualDuration: TimeInterval?
    var lastActivity: Date
    var focusScore: Double = 0.0
    var completionPercentage: Double = 0.0
    
    init(noteId: UUID, startTime: Date, targetDuration: TimeInterval) {
        self.noteId = noteId
        self.startTime = startTime
        self.targetDuration = targetDuration
        self.lastActivity = startTime
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    var elapsed: TimeInterval {
        let endTime = self.endTime ?? Date()
        return endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Export Formats
enum ExportFormat: String, CaseIterable {
    case markdown = "Markdown"
    case pdf = "PDF"
    case plainText = "Plain Text"
    case rtf = "Rich Text"
    case json = "JSON"
    
    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .pdf: return "pdf"
        case .plainText: return "txt"
        case .rtf: return "rtf"
        case .json: return "json"
        }
    }
}


/*
 import SwiftUI
 import Combine
 import UniformTypeIdentifiers

 @MainActor
 class NotesManager: ObservableObject {
     @Published var notes: [Note] = []
     @Published var selectedNote: Note?
     @Published var searchText = ""
     @Published var isProcessing = false
     @Published var errorMessage: String?
     
     private var autosaveTimer: Timer?
     private var cancellables = Set<AnyCancellable>()
     private var debouncedSaveWorkItem: DispatchWorkItem?
     private let userDefaults = UserDefaults.standard
     private let notesKey = "StudyBuddy.SavedNotes"
     
     init() {
         loadNotes()
         setupAutosave()
         setupObservers()
     }
     
     // MARK: - Setup
     private func setupObservers() {
         // Auto-select first note when notes change
         $notes
             .sink { [weak self] notes in
                 if self?.selectedNote == nil && !notes.isEmpty {
                     self?.selectedNote = notes.first
                 }
             }
             .store(in: &cancellables)
     }
     
     // MARK: - Note CRUD Operations
     func createNewNote() {
         let newNote = Note()
         notes.insert(newNote, at: 0)
         selectedNote = newNote
         saveNotes()
     }
     
     func deleteNote(_ note: Note) {
         notes.removeAll { $0.id == note.id }
         if selectedNote?.id == note.id {
             selectedNote = notes.first
         }
         saveNotes()
     }
     
     func updateNote(_ note: Note) {
         if let index = notes.firstIndex(where: { $0.id == note.id }) {
             var updatedNote = note
             updatedNote.modifiedAt = Date()
             notes[index] = updatedNote
             
             if selectedNote?.id == note.id {
                 selectedNote = updatedNote
             }
             
             // Debounced save (Swift-native)
             debouncedSaveWorkItem?.cancel()
             let workItem = DispatchWorkItem { [weak self] in
                 self?.saveNotes()
             }
             debouncedSaveWorkItem = workItem
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
         }
     }
     
     // MARK: - Search and Filter
     var filteredNotes: [Note] {
         if searchText.isEmpty {
             return notes.sorted { $0.modifiedAt > $1.modifiedAt }
         }
         
         return notes.filter { note in
             note.title.localizedCaseInsensitiveContains(searchText) ||
             note.content.localizedCaseInsensitiveContains(searchText) ||
             note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
         }.sorted { $0.modifiedAt > $1.modifiedAt }
     }
     
     // MARK: - Attachment Management
     func addAttachment(to note: Note, fileName: String, fileType: UTType, data: Data) {
         guard data.count < 10_000_000 else { // 10MB limit
             errorMessage = "File too large. Maximum size is 10MB."
             return
         }
         
         var updatedNote = note
         let attachment = Attachment(fileName: fileName, fileType: fileType, data: data)
         updatedNote.attachments.append(attachment)
         updateNote(updatedNote)
     }
     
     func removeAttachment(from note: Note, attachmentId: UUID) {
         var updatedNote = note
         updatedNote.attachments.removeAll { $0.id == attachmentId }
         updateNote(updatedNote)
     }
     
     // MARK: - Voice Note Management
     func addVoiceNote(to note: Note, audioData: Data, duration: TimeInterval) {
         guard audioData.count < 5_000_000 else { // 5MB limit for audio
             errorMessage = "Audio recording too large. Maximum size is 5MB."
             return
         }
         
         var updatedNote = note
         let voiceNote = VoiceNote(audioData: audioData, duration: duration)
         updatedNote.voiceNotes.append(voiceNote)
         updateNote(updatedNote)
     }
     
     // MARK: - Handwritten Note Management
     func addHandwrittenNote(to note: Note, imageData: Data) {
         guard imageData.count < 5_000_000 else { // 5MB limit for images
             errorMessage = "Image too large. Maximum size is 5MB."
             return
         }
         
         var updatedNote = note
         let handwrittenNote = HandwrittenNote(imageData: imageData)
         updatedNote.handwrittenImages.append(handwrittenNote)
         updateNote(updatedNote)
     }
     
     // MARK: - Export Functions
     func exportNote(_ note: Note, format: ExportFormat) -> Data? {
         switch format {
         case .markdown:
             return exportAsMarkdown(note)
         case .pdf:
             return exportAsPDF(note)
         case .plainText:
             return note.content.data(using: .utf8)
         case .rtf:
             return exportAsRTF(note)
         }
     }
     
     private func exportAsMarkdown(_ note: Note) -> Data? {
         var markdown = "# \(note.title)\n\n"
         markdown += "*Created: \(note.createdAt.formatted())*\n"
         markdown += "*Modified: \(note.modifiedAt.formatted())*\n\n"
         
         if !note.tags.isEmpty {
             markdown += "**Tags:** \(note.tags.joined(separator: ", "))\n\n"
         }
         
         if let summary = note.aiSummary {
             markdown += "## AI Summary\n\(summary)\n\n"
         }
         
         if !note.aiKeyPoints.isEmpty {
             markdown += "## Key Points\n"
             note.aiKeyPoints.forEach { point in
                 markdown += "- \(point)\n"
             }
             markdown += "\n"
         }
         
         markdown += "## Content\n\(note.content)\n"
         
         return markdown.data(using: .utf8)
     }
     
     private func exportAsPDF(_ note: Note) -> Data? {
         // PDF export would require additional implementation
         // Using NSPrintOperation or PDFKit
         return nil
     }
     
     private func exportAsRTF(_ note: Note) -> Data? {
         let attributedString = NSAttributedString(string: note.content)
         return try? attributedString.data(
             from: NSRange(location: 0, length: attributedString.length),
             documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
         )
     }
     
     // MARK: - Persistence
     func saveNotes() {
         do {
             let encoded = try JSONEncoder().encode(notes)
             userDefaults.set(encoded, forKey: notesKey)
         } catch {
             errorMessage = "Failed to save notes: \(error.localizedDescription)"
         }
     }
     
     private func loadNotes() {
         guard let data = userDefaults.data(forKey: notesKey) else {
             // Create a welcome note for first-time users
             createWelcomeNote()
             return
         }
         
         do {
             notes = try JSONDecoder().decode([Note].self, from: data)
             selectedNote = notes.first
         } catch {
             errorMessage = "Failed to load notes: \(error.localizedDescription)"
             createWelcomeNote()
         }
     }
     
     private func createWelcomeNote() {
         let welcomeNote = Note(
             title: "Welcome to Study Buddy! 🎓",
             content: """
             # Welcome to Study Buddy!
             
             Your AI-powered study companion is ready to help you succeed. Here's what you can do:
             
             ## 📝 Notes Features
             - **AI-Powered Writing**: Click the brain icon to proofread, summarize, or explain your notes
             - **Voice Notes**: Record audio notes and get automatic transcriptions
             - **Handwriting Import**: Import photos of handwritten notes with text recognition
             - **Smart Organization**: Tag and search your notes easily
             
             ## 🚀 Getting Started
             1. Create a new note with ⌘N
             2. Try the AI features in the toolbar
             3. Attach files, images, or voice recordings
             4. Generate quizzes from your notes
             
             ## 💡 Pro Tips
             - Use markdown formatting for better organization
             - The AI can help you find mistakes and improve clarity
             - Export your notes in multiple formats
             
             Happy studying! 📚
             """
         )
         notes = [welcomeNote]
         selectedNote = welcomeNote
         saveNotes()
     }
     
     private func setupAutosave() {
         autosaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
             Task { @MainActor in
                 self.saveNotes()
             }
         }
     }
     
     deinit {
         autosaveTimer?.invalidate()
     }
 }

 // MARK: - Export Formats
 enum ExportFormat: String, CaseIterable {
     case markdown = "Markdown"
     case pdf = "PDF"
     case plainText = "Plain Text"
     case rtf = "Rich Text"
     
     var fileExtension: String {
         switch self {
         case .markdown: return "md"
         case .pdf: return "pdf"
         case .plainText: return "txt"
         case .rtf: return "rtf"
         }
     }
 }
 */
