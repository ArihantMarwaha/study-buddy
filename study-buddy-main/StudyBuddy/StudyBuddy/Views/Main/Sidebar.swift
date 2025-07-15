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
    @Environment(\.colorScheme) private var colorScheme
    
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
                
                NavigationLink(value: 3) {
                    Label("Mind Map", systemImage: "rectangle.3.offgrid")
                }
                .tag(3)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Study Buddy")
        .background(
            colorScheme == .dark ? Color(NSColor.windowBackgroundColor) : Color(NSColor.controlBackgroundColor)
        )
    }
}

