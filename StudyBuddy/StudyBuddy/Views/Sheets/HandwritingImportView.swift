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
        VStack(spacing: 0) {
            // Header
            HeaderSection()
            
            // Tab Selection
            Picker("Import Method", selection: $selectedTab) {
                Label("Upload Images", systemImage: "photo.on.rectangle.angled")
                    .tag(0)
                Label("Camera Capture", systemImage: "camera")
                    .tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content Area
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
            
            // Processing Status
            if visionService.isProcessing {
                ProcessingStatusView(progress: visionService.processingProgress)
            }
            
            // Results Section
            if !processedNotes.isEmpty {
                ResultsSection(processedNotes: processedNotes)
            }
            
            Spacer()
            
            // Bottom Actions
            BottomActions(
                canProcess: !selectedImages.isEmpty && !visionService.isProcessing,
                canSave: !processedNotes.isEmpty,
                onProcess: processImages,
                onSave: saveToNote,
                onCancel: { dismiss() }
            )
        }
        .frame(width: 700, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
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
    }
    
    // MARK: - Processing
    private func processImages() {
        Task {
            do {
                processedNotes = try await visionService.processScannedDocument(selectedImages)
            } catch {
                processingError = error
            }
        }
    }
    
    private func saveToNote() {
        var updatedNote = note
        updatedNote.handwrittenImages.append(contentsOf: processedNotes)
        
        // Add recognized text to note content
        let recognizedText = processedNotes
            .compactMap { $0.recognizedText }
            .joined(separator: "\n\n")
        
        if !recognizedText.isEmpty {
            updatedNote.content += "\n\n## Handwritten Notes\n\(recognizedText)"
        }
        
        notesManager.updateNote(updatedNote)
        dismiss()
    }
    
    // MARK: - File Handling
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let images = urls.compactMap { url -> NSImage? in
                guard let image = NSImage(contentsOf: url) else { return nil }
                return image
            }
            selectedImages.append(contentsOf: images)
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
                        ResultCard(handwrittenNote: processedNotes[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.automatic)
                .frame(height: 200)
                
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
struct BottomActions: View {
    let canProcess: Bool
    let canSave: Bool
    let onProcess: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
            
            Spacer()
            
            if canProcess {
                Button("Process Images", action: onProcess)
                    .buttonStyle(.borderedProminent)
            }
            
            if canSave {
                Button("Add to Note", action: onSave)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
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
