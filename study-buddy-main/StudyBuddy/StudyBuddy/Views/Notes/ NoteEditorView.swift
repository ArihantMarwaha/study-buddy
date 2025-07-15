//
//   NoteEditorView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
import AppKit

struct NoteEditorView: View {
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var aiService: AIService
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditingTitle = false
    @State private var showingAIMenu = false
    @State private var showingAttachmentPicker = false
    @State private var showingVoiceRecorder = false
    @State private var showingHandwritingImport = false
    @State private var selectedAIAction: AIAction?
    @State private var showingQuizGenerator = false
    @State private var aiProcessingResult: AIProcessingResult?
    @State private var fontSize: CGFloat = 16
    @State private var textColor: Color = .primary
    @State private var backgroundColor: Color = .white
    @State private var borderColor: Color = .gray
    @State private var isBold: Bool = false
    @State private var isItalic: Bool = false
    @State private var isUnderlined: Bool = false
    @State private var isStrikethrough: Bool = false
    @State private var cornerRadius: CGFloat = 8
    @State private var borderWidth: CGFloat = 1
    @State private var opacity: Double = 1.0
    @State private var fontFamily: String = "System"
    @State private var showCustomizationPanel: Bool = false
    @State private var extractedText: String? = nil
    @State private var isExtractedTextExpanded: Bool = true
    
    // Computed property to get the current selected note
    private var note: Note {
        notesManager.selectedNote ?? Note()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI Controls
            EditorHeader(
                isEditingTitle: $isEditingTitle,
                showingAIMenu: $showingAIMenu,
                selectedAIAction: $selectedAIAction
            )
            .padding()
            .background(.ultraThinMaterial)
            
            // Main Editor Area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // AI Summary Card (if available)
                    if let summary = note.aiSummary {
                        AISummaryCard(summary: summary, keyPoints: note.aiKeyPoints)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    // AI Proofread/Mistake Results
                    if let result = aiProcessingResult {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("AI Feedback", systemImage: "wand.and.stars")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: { aiProcessingResult = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            Text(result.summary)
                                .font(.callout)
                                .foregroundColor(.secondary)
                            if !result.keyPoints.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Key Points:")
                                        .font(.subheadline.bold())
                                    ForEach(result.keyPoints, id: \.self) { point in
                                        Text("• " + point)
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            if !result.suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Suggestions:")
                                        .font(.subheadline.bold())
                                    ForEach(result.suggestions, id: \.self) { suggestion in
                                        Text("- " + suggestion)
                                            .font(.title3) // Increased font size
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            if !result.mistakes.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Mistakes:")
                                        .font(.subheadline.bold())
                                    ForEach(result.mistakes) { mistake in
                                        Text("• [\(mistake.type.rawValue.capitalized)] \(mistake.description) → \(mistake.suggestion)")
                                            .font(.callout)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.18))
                                .glassEffect(in: .rect(cornerRadius: 12))
                        )
                        .padding(.vertical, 8)
                    }
                    // Extracted Text Highlight
                    if let extracted = extractedText, !extracted.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Extracted Text", systemImage: "doc.text.magnifyingglass")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: { withAnimation { isExtractedTextExpanded.toggle() } }) {
                                    Image(systemName: isExtractedTextExpanded ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            if isExtractedTextExpanded {
                                ScrollView {
                                    Text(extracted)
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.2))
                                .glassEffect(in: .rect(cornerRadius: 12))
                        )
                        .padding(.vertical, 8)
                    }

                    // Text Editor
                    TextEditor(text: Binding(
                                            get: { note.content },
                                            set: { newValue in
                                                var updatedNote = note
                                                updatedNote.content = newValue
                                                notesManager.updateNote(updatedNote)
                                            }
                                        ))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .font(selectedFont())
                                        .foregroundColor(.black)
                                        .scrollContentBackground(.hidden)
                                        .background(backgroundColor)
                                        .frame(minHeight: 600)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: cornerRadius)
                                                .fill(backgroundColor.opacity(opacity))
                                                
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                        .overlay(alignment: .bottomTrailing) {
                                            if aiService.isProcessing {
                                                ProgressView()
                                                    .progressViewStyle(.circular)
                                                    .scaleEffect(0.8)
                                                    .padding()
                                            }
                                        }
                    
                    // Voice Notes Section
                    if !note.voiceNotes.isEmpty {
                        VoiceNotesSection(voiceNotes: note.voiceNotes)
                    }
                    
                    // Handwritten Notes Section
                    if !note.handwrittenImages.isEmpty {
                        HandwrittenNotesSection(handwrittenNotes: note.handwrittenImages)
                    }
                    
                    // Attachments Section
                    if !note.attachments.isEmpty {
                        AttachmentsSection(onExtractText: { text in
                            extractedText = text
                        })
                    }
                }
                .padding()
            }
            
            // Bottom Toolbar
            EditorToolbar(
                showingAttachmentPicker: $showingAttachmentPicker,
                showingVoiceRecorder: $showingVoiceRecorder,
                showingHandwritingImport: $showingHandwritingImport,
                showingQuizGenerator: $showingQuizGenerator
            )
            .padding()
            .background(.ultraThinMaterial)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showingVoiceRecorder) {
            VoiceRecorderView()
        }
        .sheet(isPresented: $showingHandwritingImport) {
            HandwritingImportView()
        }
        .sheet(isPresented: $showingQuizGenerator) {
            QuizGeneratorView()
        }
        .fileImporter(
            isPresented: $showingAttachmentPicker,
            allowedContentTypes: [.pdf, .plainText, .image, .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let data = try Data(contentsOf: url)
                    if let fileType = UTType(filenameExtension: url.pathExtension) {
                        let attachment = Attachment(fileName: url.lastPathComponent, fileType: fileType, data: data)
                        if var note = notesManager.selectedNote {
                            note.attachments.append(attachment)
                            notesManager.updateNote(note)
                        }
                    } else {
                        print("Unsupported file type")
                    }
                } catch {
                    print("Failed to import file: \(error)")
                }
            case .failure(let error):
                print("File import failed: \(error)")
            }
        }
        .task(id: selectedAIAction) {
            if let action = selectedAIAction {
                await performAIAction(action)
                selectedAIAction = nil
            }
        }
        .background(
            colorScheme == .dark ? Color(NSColor.windowBackgroundColor) : Color(NSColor.controlBackgroundColor)
        )
    }
    
    // MARK: - AI Actions
    private func performAIAction(_ action: AIAction) async {
        guard let currentNote = notesManager.selectedNote else { return }
        
        switch action {
        case .proofread:
            aiProcessingResult = await aiService.proofreadText(currentNote.content)
            // Apply corrections if needed
            
        case .summarize:
            var updatedNote = currentNote
            updatedNote.aiSummary = await aiService.summarizeText(currentNote.content)
            updatedNote.aiKeyPoints = await aiService.extractKeyPoints(from: currentNote.content)
            notesManager.updateNote(updatedNote)
            
        case .explain:
            let explanation = await aiService.explainText(currentNote.content, level: .intermediate)
            var updatedNote = currentNote
            updatedNote.content += "\n\n## AI Explanation\n\(explanation)"
            notesManager.updateNote(updatedNote)
            
        case .findMistakes:
            let result = await aiService.proofreadText(currentNote.content)
            // Show mistakes in UI
            aiProcessingResult = result
            
        case .generateNotes:
            // This would be triggered from document import
            break
        }
    }

    // MARK: - Formatting Helpers
    private func selectedFont() -> Font {
        switch fontFamily {
        case "Helvetica":
            return .custom("Helvetica", size: fontSize).weight(isBold ? .bold : .regular)
        case "Times":
            return .custom("Times New Roman", size: fontSize).weight(isBold ? .bold : .regular)
        case "Courier":
            return .custom("Courier New", size: fontSize).weight(isBold ? .bold : .regular)
        case "Georgia":
            return .custom("Georgia", size: fontSize).weight(isBold ? .bold : .regular)
        case "Verdana":
            return .custom("Verdana", size: fontSize).weight(isBold ? .bold : .regular)
        default:
            return .system(size: fontSize, weight: isBold ? .bold : .regular)
        }
    }

    private func applyFormatting() {
        // Optionally, persist formatting options to the note if desired
        // For now, only updates the UI
    }
}
// MARK: - Editor Header
struct EditorHeader: View {
    @EnvironmentObject var notesManager: NotesManager
    @Binding var isEditingTitle: Bool
    @Binding var showingAIMenu: Bool
    @Binding var selectedAIAction: AIAction?
    
    private var note: Note {
        notesManager.selectedNote ?? Note()
    }
    
    var body: some View {
        HStack {
            // Title Editor
            if isEditingTitle {
                TextField("Note Title", text: Binding(
                    get: { note.title },
                    set: { newValue in
                        var updatedNote = note
                        updatedNote.title = newValue
                        notesManager.updateNote(updatedNote)
                    }
                ), onCommit: {
                    isEditingTitle = false
                })
                .textFieldStyle(.plain)
                .font(.title2.bold())
            } else {
                Text(note.title)
                    .font(.title2.bold())
                    .onTapGesture {
                        isEditingTitle = true
                    }
            }
            
            Spacer()
            
            // AI Features Menu
            Menu {
                Button {
                    selectedAIAction = .proofread
                } label: {
                    Label("Proofread", systemImage: "text.badge.checkmark")
                }
                
                Button {
                    selectedAIAction = .summarize
                } label: {
                    Label("Summarize", systemImage: "text.bubble")
                }
                
                Button {
                    selectedAIAction = .explain
                } label: {
                    Label("Explain", systemImage: "questionmark.circle")
                }
                
                Button {
                    selectedAIAction = .findMistakes
                } label: {
                    Label("Find Mistakes", systemImage: "exclamationmark.triangle")
                }
            } label: {
                Label("AI Features", systemImage: "brain")
                    .symbolRenderingMode(.multicolor)
            }
            .menuStyle(.borderlessButton)
            .help("Use AI to enhance your notes")
            
            // Export Menu
            Menu {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button("Export as \(format.rawValue)") {
                        // Export action
                    }
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .menuStyle(.borderlessButton)
        }
    }
}


// MARK: - Voice Notes Section
struct VoiceNotesSection: View {
    @EnvironmentObject var notesManager: NotesManager
    let voiceNotes: [VoiceNote]
    @State private var isExpanded = true
    @State private var playingNoteId: UUID?
    @StateObject private var player = VoiceNotePlayer()
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Voice Notes", systemImage: "mic.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                if isExpanded {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(voiceNotes) { voiceNote in
                                let isCurrent = playingNoteId == voiceNote.id && player.isPlaying
                                VoiceNoteCard(
                                    voiceNote: voiceNote,
                                    isPlaying: isCurrent,
                                    onPlayToggle: {
                                        if isCurrent {
                                            player.stop()
                                            playingNoteId = nil
                                        } else {
                                            player.stop()
                                            player.play(data: voiceNote.audioData)
                                            playingNoteId = voiceNote.id
                                        }
                                    },
                                    onDelete: {
                                        if let note = notesManager.selectedNote {
                                            notesManager.removeVoiceNote(from: note, voiceNoteId: voiceNote.id)
                                        }
                                    },
                                    onCopyTranscript: {
                                        if let transcript = voiceNote.transcript, var note = notesManager.selectedNote {
                                            note.content += "\n\n## Voice Note Transcript\n" + transcript
                                            notesManager.updateNote(note)
                                        }
                                    },
                                    currentTime: isCurrent ? player.currentTime : 0.0,
                                    duration: isCurrent ? player.duration : voiceNote.duration,
                                    onSeek: { time in
                                        if isCurrent {
                                            player.seek(to: time)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.18))
                    .glassEffect(in: .rect(cornerRadius: 16))
            )
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
        .onChange(of: player.isPlaying) { isPlaying in
            if !isPlaying {
                playingNoteId = nil
            }
        }
    }
}



// MARK: - Handwritten Notes Section
struct HandwrittenNotesSection: View {
    @EnvironmentObject var notesManager: NotesManager
    @State var handwrittenNotes: [HandwrittenNote]
    @State private var isEditMode = false
    @State private var isExpanded = true
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isEditMode.toggle()
                            }
                        }) {
                            Image(systemName: isEditMode ? "xmark" : "square.and.pencil")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isEditMode ? .red : .white)
                                .frame(width: 30, height: 32)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 1)
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isEditMode)
                    Label("Handwritten Notes", systemImage: "pencil.tip")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                if isExpanded {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(handwrittenNotes) { note in
                                HandwrittenNoteCard(
                                    handwrittenNote: note,
                                    onDelete: isEditMode ? {
                                        if let idx = handwrittenNotes.firstIndex(of: note) {
                                            handwrittenNotes.remove(at: idx)
                                            if var selected = notesManager.selectedNote {
                                                selected.handwrittenImages = handwrittenNotes
                                                notesManager.updateNote(selected)
                                            }
                                        }
                                    } : nil
                                )
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isEditMode)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.18))
                    .glassEffect(in: .rect(cornerRadius: 16))
            )
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
    }
}

struct AttachmentsSection: View {
    @EnvironmentObject var notesManager: NotesManager
    var onExtractText: ((String) -> Void)? = nil
    @State private var isEditMode = false
    @State private var isExpanded = true

    var attachments: [Attachment] {
        notesManager.selectedNote?.attachments ?? []
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isEditMode.toggle()
                            }
                        }) {
                            Image(systemName: isEditMode ? "xmark" : "paperclip")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isEditMode ? .red : .white)
                                .frame(width: 30, height: 32)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 1)
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isEditMode)
                    Label("Attachments", systemImage: "paperclip")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                if isExpanded {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(attachments) { attachment in
                                AttachmentCard(
                                    attachment: attachment,
                                    onExtractText: onExtractText, // Pass the closure
                                    onDelete: isEditMode ? {
                                        if let note = notesManager.selectedNote {
                                            notesManager.removeAttachment(from: note, attachmentId: attachment.id)
                                        }
                                    } : nil
                                )
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isEditMode)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.18))
                    .glassEffect(in: .rect(cornerRadius: 16))
            )
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
    }
}


#Preview {
    let notesManager = NotesManager()
    let sampleNote = Note(
        title: "Sample Note",
        content: "This is a sample note content to show how the editor looks."
    )
    notesManager.notes = [sampleNote]
    notesManager.selectedNote = sampleNote
    
    return NoteEditorView()
        .environmentObject(notesManager)
        .environmentObject(AIService())
}

internal import Combine
internal import UniformTypeIdentifiers
enum AIAction {
    case proofread
    case summarize
    case explain
    case findMistakes
    case generateNotes
}
