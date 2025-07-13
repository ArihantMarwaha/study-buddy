//
//  Sidebar.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI

struct Sidebar: View {
    @Binding var selectedTab: Int?
    @EnvironmentObject var notesManager: NotesManager
    
    var body: some View {
        List(selection: $selectedTab) {
            Section {
                Label("Notes", systemImage: "note.text")
                    .tag(1)
                    .badge(notesManager.notes.count)
                
                Label("Daily Tasks", systemImage: "checklist")
                    .tag(0)
                
                Label("Mental Health", systemImage: "heart.circle")
                    .tag(2)
                    .badge("Soon")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Study Buddy")
    }
}

