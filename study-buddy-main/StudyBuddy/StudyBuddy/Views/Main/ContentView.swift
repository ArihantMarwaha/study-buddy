//
//  ContentView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
import AppKit


struct ContentView: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var selectedTab: Int? = 0
    
    var body: some View {
        NavigationSplitView {
            Sidebar(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            switch selectedTab ?? 0 {
            case 0:
                NotesView()
            case 1:
                DailyTaskMasterView()
            case 3:
                MindMapView()
            default:
                EmptyView()
            }
        }
        .onAppear {
            goFullScreen()
        }
    }
}

// Helper to make the window fullscreen
private func goFullScreen() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        if let window = NSApp.windows.first {
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }
}

