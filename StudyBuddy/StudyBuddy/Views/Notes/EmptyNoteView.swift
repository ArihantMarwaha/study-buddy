//
//  EmptyNoteView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
// MARK: - Empty Note View
struct EmptyNoteView: View {
    @EnvironmentObject var notesManager: NotesManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            Text("No Note Selected")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Select a note from the sidebar or create a new one")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Button(action: {
                notesManager.createNewNote()
            }) {
                Label("Create New Note", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

