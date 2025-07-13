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
    
    var body: some View {
        VStack {
            if let imageData = handwrittenNote.enhancedImageData ?? handwrittenNote.imageData,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .cornerRadius(8)
            }
            
            if handwrittenNote.smudgeDetected {
                Label("Smudge Detected", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}
