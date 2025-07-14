//
//  NotesListView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

// MARK: - Notes List View
struct NotesListView: View {
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var aiService: AIService
    @State private var showingImporter = false
    @State private var selectedImportType: ImportType?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search notes...", text: $notesManager.searchText)
                    .textFieldStyle(.plain)
                
                if !notesManager.searchText.isEmpty {
                    Button(action: { notesManager.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding()
            
            // Notes List
            if notesManager.filteredNotes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: notesManager.searchText.isEmpty ? "note.text" : "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text(notesManager.searchText.isEmpty ? "No notes yet" : "No notes found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if notesManager.searchText.isEmpty {
                        Button("Create Your First Note") {
                            notesManager.createNewNote()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                List(selection: $notesManager.selectedNote) {
                    ForEach(notesManager.filteredNotes) { note in
                        NoteRow(note: note)
                            .tag(note)
                            .contextMenu {
                                noteContextMenu(for: note)
                            }
                    }
                }
                .listStyle(.sidebar)
            }
            
            // Bottom Toolbar
            HStack {
                Button(action: { notesManager.createNewNote() }) {
                    Label("New Note", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .help("Create a new note (⌘N)")
                
                Spacer()
                
                Menu {
                    Button(action: {
                        selectedImportType = .document
                        showingImporter = true
                    }) {
                        Label("Import Document", systemImage: "doc.badge.plus")
                    }
                    
                    Button(action: {
                        selectedImportType = .audio
                        showingImporter = true
                    }) {
                        Label("Import Audio", systemImage: "waveform.badge.plus")
                    }
                    
                    Button(action: {
                        selectedImportType = .image
                        showingImporter = true
                    }) {
                        Label("Import Image", systemImage: "photo.badge.plus")
                    }
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .menuStyle(.borderlessButton)
                .help("Import files into notes")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .navigationTitle("Notes")
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private var allowedContentTypes: [UTType] {
        switch selectedImportType {
        case .document:
            return [.pdf, .plainText, .rtfd, .rtf]
        case .audio:
            return [.audio, .mp3, .wav, UTType(filenameExtension: "m4a")!]
        case .image:
            return [.image, .png, .jpeg, .heic]
        case .none:
            return []
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    let data = try Data(contentsOf: url)
                    _ = url.lastPathComponent
                    
                    switch selectedImportType {
                    case .document:
                        // Process document and create note
                        let note = await aiService.generateNotesFromDocument(
                            data,
                            fileType: UTType(filenameExtension: url.pathExtension) ?? .data
                        )
                        notesManager.notes.insert(note, at: 0)
                        notesManager.selectedNote = note
                        notesManager.saveNotes()
                        
                    case .audio:
                        // Add to current note or create new one
                        if let currentNote = notesManager.selectedNote {
                            await notesManager.addVoiceNote(
                                to: currentNote,
                                audioData: data,
                                duration: 0 // Would calculate actual duration
                            )
                        } else {
                            notesManager.createNewNote()
                            if let newNote = notesManager.selectedNote {
                                await notesManager.addVoiceNote(
                                    to: newNote,
                                    audioData: data,
                                    duration: 0
                                )
                            }
                        }
                        
                    case .image:
                        // Add to current note or create new one
                        if let currentNote = notesManager.selectedNote {
                            await notesManager.addHandwrittenNote(
                                to: currentNote,
                                imageData: data
                            )
                        } else {
                            notesManager.createNewNote()
                            if let newNote = notesManager.selectedNote {
                                await notesManager.addHandwrittenNote(
                                    to: newNote,
                                    imageData: data
                                )
                            }
                        }
                        
                    case .none:
                        break
                    }
                } catch {
                    notesManager.errorMessage = "Failed to import file: \(error.localizedDescription)"
                }
            }
            
        case .failure(let error):
            notesManager.errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
    
    @ViewBuilder
    private func noteContextMenu(for note: Note) -> some View {
        Button(action: {
            // Duplicate note
            var duplicatedNote = note
            duplicatedNote.title = "\(note.title) (Copy)"
            duplicatedNote.createdAt = Date()
            duplicatedNote.modifiedAt = Date()
            notesManager.notes.insert(duplicatedNote, at: 0)
            notesManager.selectedNote = duplicatedNote
            notesManager.saveNotes()
        }) {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        
        Menu {
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Button(format.rawValue) {
                    exportNote(note, format: format)
                }
            }
        } label: {
            Label("Export as...", systemImage: "square.and.arrow.up")
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            notesManager.deleteNote(note)
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func exportNote(_ note: Note, format: ExportFormat) {
        guard let data = notesManager.exportNote(note, format: format) else {
            notesManager.errorMessage = "Export failed"
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: format.fileExtension) ?? .data]
        savePanel.nameFieldStringValue = "\(note.title).\(format.fileExtension)"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                } catch {
                    notesManager.errorMessage = "Failed to save file: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        // Search Bar
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search notes...", text: .constant(""))
                .textFieldStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
        .padding()
        
        // Sample Notes List
        List {
            VStack(alignment: .leading, spacing: 4) {
                Text("First Note")
                    .font(.headline)
                    .lineLimit(1)
                Text("This is the first sample note.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                HStack {
                    Text("Dec 7, 2025 at 2:30 PM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Second Note")
                    .font(.headline)
                    .lineLimit(1)
                Text("This is the second sample note with more content.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                HStack {
                    Text("Dec 7, 2025 at 2:00 PM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.sidebar)
        
        // Bottom Toolbar
        HStack {
            Button(action: {}) {
                Label("New Note", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Menu {
                Button("Import Document") {}
                Button("Import Audio") {}
                Button("Import Image") {}
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .menuStyle(.borderlessButton)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    .frame(width: 300)
}

