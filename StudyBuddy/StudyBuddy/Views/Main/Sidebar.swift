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
                NavigationLink(value: 0) {
                    Label("Notes", systemImage: "note.text")
                        .badge(notesManager.notes.count)
                }
                .tag(0)
                
                NavigationLink(value: 1) {
                    Label("Daily Tasks", systemImage: "checklist")
                }
                .tag(1)
                
                NavigationLink(value: 2) {
                    Label("Mental Health", systemImage: "heart.circle")
                        .badge("Soon")
                }
                .tag(2)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Study Buddy")
    }
}

