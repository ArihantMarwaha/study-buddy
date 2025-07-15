//
//  StudyBuddyApp.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI

import SwiftUI
import Foundation
import UserNotifications
import AVFoundation

@main
struct StudyBuddyApp: App {
    @StateObject private var notesManager = NotesManager()
    @StateObject private var aiService = AIService()
    @StateObject private var goalManager = GoalManager() // Add GoalManager
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notesManager)
                .environmentObject(aiService)
                .environmentObject(goalManager) // Provide GoalManager
                .background(WindowBackgroundView())
                .onAppear {
                    requestNotificationPermissions()
                    setupAppIntents()
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 100, height: 100) // Set default size
        .windowResizability(.contentSize) // Enforce minimum size
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    notesManager.createNewNote()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("Notes") {
                Button("Export Current Note...") {
                    // Export functionality
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(notesManager.selectedNote == nil)
                Divider()
                Button("Generate Quiz") {
                    // Quiz generation
                }
                .keyboardShortcut("q", modifiers: [.command, .shift])
                .disabled(notesManager.selectedNote == nil)
            }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func setupAppIntents() {
        // Register app intents
    }
}

// Window Background View for Glass Effect simulation
struct WindowBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ComingSoonView: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.multicolor)
            
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            
            Text(description)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

 internal import Combine
@MainActor
class VoiceNotePlayer: NSObject,ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    private var timer: Timer?

    func play(data: Data) {
        stop()
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            duration = audioPlayer?.duration ?? 0
            startTimer()
        } catch {
            print("Failed to play audio: \(error)")
            isPlaying = false
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        stopTimer()
        currentTime = 0
        duration = 0
    }

    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
        currentTime = time
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension VoiceNotePlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}


