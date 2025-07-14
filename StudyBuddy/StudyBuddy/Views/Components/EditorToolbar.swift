//
//  EditorToolbar.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
struct EditorToolbar: View {
    @Binding var showingAttachmentPicker: Bool
    @Binding var showingVoiceRecorder: Bool
    @Binding var showingHandwritingImport: Bool
    @Binding var showingQuizGenerator: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                showingAttachmentPicker = true
            } label: {
                Label("Attach", systemImage: "paperclip")
            }
            .help("Attach files to this note")
            
            Button {
                showingVoiceRecorder = true
            } label: {
                Label("Voice Note", systemImage: "mic")
            }
            .help("Record a voice note")
            
            Button {
                showingHandwritingImport = true
            } label: {
                Label("Handwriting", systemImage: "pencil.tip")
            }
            .help("Import handwritten notes")
            
            Spacer()
            
            Button {
                showingQuizGenerator = true
            } label: {
                Label("Generate Quiz", systemImage: "questionmark.app")
            }
            .buttonStyle(.borderedProminent)
            .help("Generate a quiz from this note")
        }
    }
}

#Preview {
    EditorToolbar(
        showingAttachmentPicker: .constant(false),
        showingVoiceRecorder: .constant(false),
        showingHandwritingImport: .constant(false),
        showingQuizGenerator: .constant(false)
    )
    .padding()
}

