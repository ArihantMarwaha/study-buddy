//
//  HandwritingImportView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct HandwritingImportView: View {
    @EnvironmentObject var notesManager: NotesManager
    @StateObject private var visionService = VisionService()
    @Environment(\.dismiss) private var dismiss
    
    private var note: Note {
        notesManager.selectedNote ?? Note()
    }
    
    @State private var selectedImages: [NSImage] = []
    @State private var processedNotes: [HandwrittenNote] = []
    @State private var showingImagePicker = false
    @State private var dragOver = false
    @State private var selectedTab = 0
    @State private var processingError: Error?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    HeaderSection()
                    Picker("Import Method", selection: $selectedTab) {
                        Label("Upload Images", systemImage: "photo.on.rectangle.angled")
                            .tag(0)
                        Label("Camera Capture", systemImage: "camera")
                            .tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    if selectedTab == 0 {
                        UploadSection(
                            selectedImages: $selectedImages,
                            dragOver: $dragOver,
                            showingImagePicker: $showingImagePicker,
                            onDrop: handleDrop
                        )
                    } else {
                        CameraCaptureSection()
                    }
                    if visionService.isProcessing {
                        ProcessingStatusView(progress: visionService.processingProgress)
                    }
                    if !processedNotes.isEmpty {
                        ResultsSection(processedNotes: processedNotes)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 80) // Add space for toolbar
            }
            .frame(width: 700, height: 600)
            .background(Color(NSColor.windowBackgroundColor))
            .fileImporter(
                isPresented: $showingImagePicker,
                allowedContentTypes: [.image, .pdf],
                allowsMultipleSelection: true
            ) { result in
                handleFileSelection(result)
            }
            .alert("Processing Error", isPresented: .constant(processingError != nil)) {
                Button("OK") {
                    processingError = nil
                }
            } message: {
                Text(processingError?.localizedDescription ?? "An error occurred")
            }
            // Fixed toolbar overlay
            BottomToolbar(
                canProcess: !selectedImages.isEmpty && !visionService.isProcessing,
                canSave: !processedNotes.isEmpty,
                hasProcessedNotes: !processedNotes.isEmpty,
                onProcess: processImages,
                onSave: saveToNote,
                onCancel: { dismiss() },
                onNewImport: !processedNotes.isEmpty ? { processedNotes.removeAll() } : nil
            )
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .shadow(radius: 8)
        }
    }
    
    // MARK: - Processing
    private func processImages() {
        Task {
            do {
                processedNotes = try await visionService.processScannedDocument(selectedImages)
                selectedImages.removeAll() // Clear images after processing
            } catch {
                processingError = error
            }
        }
    }
    
    private func saveToNote() {
        var updatedNote = note
        updatedNote.handwrittenImages.append(contentsOf: processedNotes)
        
        // Add recognized text and transcript to note content
        let handwrittenSections = processedNotes.map { note in
            var section = ""
            if let imageData = note.imageData, !imageData.isEmpty {
                section += "\n\n## Handwritten Note\n"
                if let text = note.recognizedText, !text.isEmpty {
                    section += text
                }
            } else if let transcript = note.transcript, !transcript.isEmpty {
                section += "\n\n## PDF Handwritten Transcript\n"
                section += transcript
            }
            return section
        }.joined(separator: "\n\n")
        
        if !handwrittenSections.isEmpty {
            updatedNote.content += handwrittenSections
        }
        
        notesManager.updateNote(updatedNote)
        dismiss()
    }
    
    // MARK: - File Handling
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                var newImages: [NSImage] = []
                var newNotes: [HandwrittenNote] = []
                for url in urls {
                    if url.pathExtension.lowercased() == "pdf" {
                        do {
                            let extractedText = try await visionService.recognizeText(fromPDF: url)
                            // Create a HandwrittenNote with transcript for PDF
                            var note = HandwrittenNote(imageData: Data())
                            note.recognizedText = "PDF Extracted Text"
                            note.transcript = extractedText
                            newNotes.append(note)
                        } catch {
                            processingError = error
                        }
                    } else if let image = NSImage(contentsOf: url) {
                        newImages.append(image)
                    }
                }
                if !newImages.isEmpty {
                    selectedImages.append(contentsOf: newImages)
                }
                if !newNotes.isEmpty {
                    processedNotes.append(contentsOf: newNotes)
                }
            }
        case .failure(let error):
            processingError = error
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                provider.loadObject(ofClass: NSImage.self) { image, error in
                    if let image = image as? NSImage {
                        DispatchQueue.main.async {
                            self.selectedImages.append(image)
                        }
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .symbolRenderingMode(.multicolor)
            
            Text("Import Handwritten Notes")
                .font(.title2.bold())
            
            Text("Upload images or capture with camera")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Upload Section
struct UploadSection: View {
    @Binding var selectedImages: [NSImage]
    @Binding var dragOver: Bool
    @Binding var showingImagePicker: Bool
    let onDrop: ([NSItemProvider]) -> Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Drop Zone
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [5]),
                        antialiased: true
                    )
                    .foregroundColor(dragOver ? .blue : .secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(dragOver ? Color.blue.opacity(0.1) : Color.clear)
                    )
                
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Drop images here or")
                        .font(.headline)
                    
                    Button("Browse Files") {
                        showingImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(height: 200)
            .onDrop(of: [.image], isTargeted: $dragOver, perform: onDrop)
            
            // Selected Images Preview
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            ImageThumbnail(
                                image: selectedImages[index],
                                onRemove: {
                                    selectedImages.remove(at: index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 120)
            }
        }
        .padding()
    }
}

// MARK: - Image Thumbnail
struct ImageThumbnail: View {
    let image: NSImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.red))
            }
            .buttonStyle(.plain)
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Camera Capture Section
struct CameraCaptureSection: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Camera Capture")
                .font(.title3.bold())
            
            Text("Position your handwritten notes in the viewfinder")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Open Camera") {
                // In real implementation, would open camera view
                print("Camera feature would open here")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Processing Status View
struct ProcessingStatusView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress) {
                Text("Processing...")
                    .font(.headline)
            }
            .progressViewStyle(.linear)
            
            Text("\(Int(progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
        .padding()
    }
}

// MARK: - Results Section
struct ResultsSection: View {
    let processedNotes: [HandwrittenNote]
    @State private var selectedNoteIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recognition Results", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)
            
            if !processedNotes.isEmpty {
                TabView(selection: $selectedNoteIndex) {
                    ForEach(processedNotes.indices, id: \.self) { index in
                        if let imageData = processedNotes[index].imageData, !imageData.isEmpty, let image = NSImage(data: imageData) {
                            ResultCard(handwrittenNote: processedNotes[index])
                                .tag(index)
                        } else {
                            PDFResultCard(handwrittenNote: processedNotes[index])
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.automatic)
                .frame(height: 250)
                
                if processedNotes.count > 1 {
                    Text("Page \(selectedNoteIndex + 1) of \(processedNotes.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
    }
}

// MARK: - PDF Result Card
struct PDFResultCard: View {
    let handwrittenNote: HandwrittenNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("PDF Document", systemImage: "doc.richtext")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            ScrollView {
                Text(handwrittenNote.recognizedText ?? "No text recognized")
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.ultraThinMaterial)
            )
            
            if let transcript = handwrittenNote.transcript, !transcript.isEmpty {
                Divider()
                Text("Transcript:")
                    .font(.caption.bold())
                ScrollView {
                    Text(transcript)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.07))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.07))
        )
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let handwrittenNote: HandwrittenNote
    @State private var showingOriginal = true
    
    var body: some View {
        HStack(spacing: 16) {
            // Image Preview
            VStack {
                if showingOriginal,
                   let imageData = handwrittenNote.imageData,
                   let image = NSImage(data: imageData) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .cornerRadius(8)
                } else if !showingOriginal,
                          let enhancedData = handwrittenNote.enhancedImageData,
                          let enhancedImage = NSImage(data: enhancedData) {
                    Image(nsImage: enhancedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .cornerRadius(8)
                }
                
                if handwrittenNote.enhancedImageData != nil {
                    Toggle("Show Enhanced", isOn: $showingOriginal.not)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .frame(width: 200)
            
            // Recognized Text
            VStack(alignment: .leading, spacing: 8) {
                if handwrittenNote.smudgeDetected {
                    Label("Smudge detected and cleaned", systemImage: "wand.and.stars")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                ScrollView {
                    Text(handwrittenNote.recognizedText ?? "No text recognized")
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .padding()
    }
}

// MARK: - Bottom Actions
struct BottomToolbar: View {
    let canProcess: Bool
    let canSave: Bool
    let hasProcessedNotes: Bool
    let onProcess: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onNewImport: (() -> Void)?
    
    @State private var showSavedConfirmation = false
    
    var body: some View {
        HStack {
            Button {
                onCancel()
            } label: {
                Label("Cancel", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
            .help("Close and discard changes")
            Spacer()
            if canProcess {
                Button {
                    onProcess()
                } label: {
                    Label("Process Images", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .help("Run handwriting recognition on selected images")
            }
            if hasProcessedNotes, let onNewImport = onNewImport {
                Button {
                    onNewImport()
                } label: {
                    Label("New Import", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .help("Start a new handwritten note import")
            }
            Button {
                onSave()
                showSavedConfirmation = true
            } label: {
                Label("Save to Note", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
            .help(canSave ? "Add recognized notes to your current note" : "No processed notes to save yet")
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .alert("Handwritten notes saved!", isPresented: $showSavedConfirmation) {
            Button("OK", role: .cancel) {}
        }
    }
}

// MARK: - Helper Extensions
extension Binding where Value == Bool {
    var not: Binding<Bool> {
        Binding<Bool>(
            get: { !self.wrappedValue },
            set: { self.wrappedValue = !$0 }
        )
    }
}

// MARK: - Preview
#Preview {
    HandwritingImportView()
        .environmentObject(NotesManager())
}
