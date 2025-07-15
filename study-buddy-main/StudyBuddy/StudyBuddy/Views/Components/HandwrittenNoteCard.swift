//
//  HandwrittenNoteCard.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI

// MARK: - Handwritten Note Card
struct HandwrittenNoteCard: View {
    let handwrittenNote: HandwrittenNote
    var onDelete: (() -> Void)? = nil
    @State private var showPreview = false
    @EnvironmentObject private var notesManager: NotesManager
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Glass-like background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            VStack(spacing: 8) {
                if let imageData = handwrittenNote.enhancedImageData ?? handwrittenNote.imageData,
                   let nsImage = NSImage(data: imageData) {
                    GeometryReader { geo in
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .onTapGesture {
                                showPreview = true
                            }
                            .accessibilityLabel("Tap to preview image")
                    }
                    .frame(height: 180)
                    .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.08))
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        )
                }
                if handwrittenNote.smudgeDetected {
                    Label("Smudge Detected", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    // Show enhance button if not already enhanced
                    if handwrittenNote.enhancedImageData == nil, let imageData = handwrittenNote.imageData, let nsImage = NSImage(data: imageData) {
                        Button {
                            enhanceImage(nsImage)
                        } label: {
                            Label("Enhance Image", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        .padding(.top, 4)
                    }
                }
            }
            .padding(12)
            // Delete button overlay
            if let onDelete = onDelete {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 1)
                    )
                    .padding([.top, .trailing], 10)
                }
            }
        }
        .frame(minWidth: 160, maxWidth: 260, minHeight: 200)
        .padding(6)
        .sheet(isPresented: $showPreview) {
            if let imageData = handwrittenNote.enhancedImageData ?? handwrittenNote.imageData,
               let nsImage = NSImage(data: imageData) {
                VStack {
                    Spacer()
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 600, maxHeight: 600)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(16)
                        .padding()
                    Spacer()
                    Button("Close") {
                        showPreview = false
                    }
                    .keyboardShortcut(.cancelAction)
                    .padding(.bottom, 24)
                }
                .frame(minWidth: 400, minHeight: 400)
                .background(Color.black.opacity(0.85))
            }
        }
    }
    
    private func enhanceImage(_ nsImage: NSImage) {
        // Run enhancement and update the note in NotesManager
        Task {
            guard let inputImage = CIImage(data: nsImage.tiffRepresentation ?? Data()) else { return }
            let context = CIContext()
            if let enhanced = VisionService().enhanceHandwrittenImage(inputImage, context: context),
               let enhancedData = enhanced.tiffRepresentation {
                // Find and update the note in NotesManager
                if var selected = notesManager.selectedNote {
                    if let idx = selected.handwrittenImages.firstIndex(where: { $0.id == handwrittenNote.id }) {
                        selected.handwrittenImages[idx].enhancedImageData = enhancedData
                        notesManager.updateNote(selected)
                    }
                }
            }
        }
    }
}

#Preview {
    let sampleImage = NSImage(size: NSSize(width: 150, height: 150))
    let imageData = sampleImage.tiffRepresentation ?? Data()
    let handwrittenNote = HandwrittenNote(imageData: imageData)
    return HandwrittenNoteCard(handwrittenNote: handwrittenNote)
}
