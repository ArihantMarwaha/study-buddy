//
//  NotesManager.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//




 import SwiftUI
 internal import Combine
 internal import UniformTypeIdentifiers

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
 
