//
//  NotesView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct NotesView: View {
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var aiService: AIService
    @State private var showingNewNote = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Notes List
            NotesListView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // Note Editor
            if notesManager.selectedNote != nil {
                NoteEditorView()
            } else {
                EmptyNoteView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .alert("Error", isPresented: .constant(notesManager.errorMessage != nil)) {
            Button("OK") {
                notesManager.errorMessage = nil
            }
        } message: {
            Text(notesManager.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    NotesView()
        .environmentObject(NotesManager())
        .environmentObject(AIService())
}





// MARK: - Supporting Types
enum ImportType {
    case document
    case audio
    case image
}
