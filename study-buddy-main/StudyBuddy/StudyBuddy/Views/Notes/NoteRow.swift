//
//  NoteRow.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI

// MARK: - Note Row
struct NoteRow: View {
    let note: Note
    @EnvironmentObject var notesManager: NotesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text(note.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Indicators
                HStack(spacing: 4) {
                    if note.aiSummary != nil {
                        Image(systemName: "brain")
                            .font(.caption)
                            .foregroundColor(.white)
                            .help("AI processed")
                    }
                    if !note.voiceNotes.isEmpty {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .help("\(note.voiceNotes.count) voice note(s)")
                    }
                    if !note.handwrittenImages.isEmpty {
                        Image(systemName: "pencil.tip")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .help("\(note.handwrittenImages.count) handwritten note(s)")
                    }
                    if !note.attachments.isEmpty {
                        Image(systemName: "paperclip")
                            .font(.caption)
                            .foregroundColor(.green)
                            .help("\(note.attachments.count) attachment(s)")
                    }
                }
            }
            
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 20)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            notesManager.selectedNote = note
        }
    }
}

private var sampleNote: Note {
    var note = Note(
        title: "Sample Note Title",
        content: "Sample note content goes here. This is just for preview purposes."
    )
    note.tags = ["Swift", "Xcode"]
    return note
}

#Preview {
    NoteRow(note: sampleNote)
        .environmentObject(NotesManager())
}
