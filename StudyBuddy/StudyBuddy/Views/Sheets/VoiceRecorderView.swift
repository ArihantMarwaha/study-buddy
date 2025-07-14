//
//  VoiceRecorderView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
import SwiftUI
import AVFoundation
internal import Combine

struct VoiceRecorderView: View {
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var aiService: AIService
    @StateObject private var audioService = AudioService()
    @Environment(\.dismiss) private var dismiss
    
    private var note: Note {
        notesManager.selectedNote ?? Note()
    }
    
    @State private var recordingURL: URL?
    @State private var isTranscribing = false
    @State private var transcribedText = ""
    @State private var showingTranscript = false
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 0, count: 30)
    @State private var waveformColors: [Color] = Array(repeating: .blue, count: 30)
    @State private var waveformScales: [CGFloat] = Array(repeating: 1.0, count: 30)
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(audioService.isRecording ? .red : .blue)
                    .symbolEffect(.bounce, value: audioService.isRecording)
                
                Text(audioService.isRecording ? "Recording..." : "Voice Note")
                    .font(.title2.bold())
                
                if audioService.isRecording {
                    Text(formatTime(audioService.recordingTime))
                        .font(.title3.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            
            // Waveform Visualizer
            EnhancedWaveformView(
                amplitudes: waveformAmplitudes,
                colors: waveformColors,
                scales: waveformScales,
                isRecording: audioService.isRecording,
                audioLevel: CGFloat(audioService.audioLevel)
            )
            .frame(height: 120)
            .padding(.horizontal)
            
            // Recording Controls
            HStack(spacing: 40) {
                // Cancel/Delete Button
                Button(action: cancelOrDelete) {
                    Image(systemName: audioService.isRecording ? "xmark.circle.fill" : "trash.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!audioService.isRecording && recordingURL == nil)
                
                // Record/Stop Button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(audioService.isRecording ? Color.red : Color.blue)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: audioService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(audioService.isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: audioService.isRecording)
                
                // Save/Transcribe Button
                Button(action: saveOrTranscribe) {
                    Image(systemName: showingTranscript ? "checkmark.circle.fill" : "text.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .disabled(recordingURL == nil || audioService.isRecording)
            }
            
            // Transcription Section
            if showingTranscript && !transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Transcript", systemImage: "text.bubble")
                            .font(.headline)
                        
                        Spacer()
                        
                        if isTranscribing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    ScrollView {
                        Text(transcribedText)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .frame(maxHeight: 150)
                    
                    HStack {
                        Button("Add to Note") {
                            addTranscriptToNote()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Translate") {
                            // Implement translation
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .glassEffect(in: .rect(cornerRadius: 12))
                )
            }
            
            Spacer()
            
            // Bottom Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save Voice Note") {
                    saveVoiceNote()
                }
                .buttonStyle(.borderedProminent)
                .disabled(recordingURL == nil || audioService.isRecording)
            }
        }
        .padding(30)
        .frame(width: 500, height: showingTranscript ? 700 : 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateWaveform()
        }
        .alert("No Microphone Permission", isPresented: .constant(!audioService.hasRecordingPermission)) {
            Button("Open Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Study Buddy needs access to your microphone to record voice notes.")
        }
    }
    
    // MARK: - Actions
    private func toggleRecording() {
        if audioService.isRecording {
            if let result = audioService.stopRecording() {
                recordingURL = result.url
                Task {
                    await transcribeAudio()
                }
            }
        } else {
            recordingURL = audioService.startRecording()
            transcribedText = ""
            showingTranscript = false
        }
    }
    
    private func cancelOrDelete() {
        if audioService.isRecording {
            _ = audioService.stopRecording()
        }
        recordingURL = nil
        transcribedText = ""
        showingTranscript = false
        waveformAmplitudes = Array(repeating: 0, count: 30)
        waveformColors = Array(repeating: .blue, count: 30)
        waveformScales = Array(repeating: 1.0, count: 30)
    }
    
    private func saveOrTranscribe() {
        if !showingTranscript {
            showingTranscript = true
            if transcribedText.isEmpty {
                Task {
                    await transcribeAudio()
                }
            }
        } else {
            saveVoiceNote()
        }
    }
    
    private func saveVoiceNote() {
        guard let url = recordingURL,
              let audioData = audioService.loadAudioData(from: url) else { return }
        
        var voiceNote = VoiceNote(
            audioData: audioData,
            duration: audioService.recordingTime
        )
        voiceNote.transcript = transcribedText.isEmpty ? nil : transcribedText
        
        var updatedNote = note
        updatedNote.voiceNotes.append(voiceNote)
        notesManager.updateNote(updatedNote)
        
        dismiss()
    }
    
    private func addTranscriptToNote() {
        var updatedNote = note
        updatedNote.content += "\n\n## Voice Note Transcript\n\(transcribedText)"
        notesManager.updateNote(updatedNote)
        dismiss()
    }
    
    private func transcribeAudio() async {
        guard let url = recordingURL,
              let audioData = audioService.loadAudioData(from: url) else { return }
        
        isTranscribing = true
        transcribedText = await aiService.transcribeAudio(audioData)
        isTranscribing = false
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateWaveform() {
        guard audioService.isRecording else { return }
        
        let currentLevel = CGFloat(audioService.audioLevel)
        let normalizedLevel = min(currentLevel * 2.0, 1.0) // Amplify the effect
        
        // Shift existing arrays
        waveformAmplitudes.removeFirst()
        waveformColors.removeFirst()
        waveformScales.removeFirst()
        
        // Add new values with dynamic effects
        waveformAmplitudes.append(normalizedLevel)
        
        // Dynamic color based on intensity
        let intensity = normalizedLevel
        let newColor: Color
        if intensity > 0.8 {
            newColor = .red
        } else if intensity > 0.6 {
            newColor = .orange
        } else if intensity > 0.4 {
            newColor = .yellow
        } else if intensity > 0.2 {
            newColor = .green
        } else {
            newColor = .blue
        }
        waveformColors.append(newColor)
        
        // Dynamic scale based on intensity
        let scale = 1.0 + (intensity * 0.3)
        waveformScales.append(scale)
    }
}

// MARK: - Enhanced Waveform Visualizer
struct EnhancedWaveformView: View {
    let amplitudes: [CGFloat]
    let colors: [Color]
    let scales: [CGFloat]
    let isRecording: Bool
    let audioLevel: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<amplitudes.count, id: \.self) { index in
                    EnhancedWaveformBar(
                        amplitude: amplitudes[index],
                        color: colors[index],
                        scale: scales[index],
                        isActive: isRecording && index == amplitudes.count - 1,
                        index: index
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct EnhancedWaveformBar: View {
    let amplitude: CGFloat
    let color: Color
    let scale: CGFloat
    let isActive: Bool
    let index: Int
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar (mirrored)
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 6)
                .frame(height: max(3, amplitude * 60))
                .scaleEffect(y: scale, anchor: .bottom)
                .opacity(isActive ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.15), value: amplitude)
                .animation(.easeOut(duration: 0.2), value: scale)
                .animation(.easeOut(duration: 0.3), value: color)
            
            // Center dot for active bar
            if isActive {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                    .opacity(isAnimating ? 0.7 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
            } else {
                Circle()
                    .fill(color.opacity(0.6))
                    .frame(width: 4, height: 4)
            }
            
            // Bottom bar (mirrored)
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 6)
                .frame(height: max(3, amplitude * 60))
                .scaleEffect(y: scale, anchor: .top)
                .opacity(isActive ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.15), value: amplitude)
                .animation(.easeOut(duration: 0.2), value: scale)
                .animation(.easeOut(duration: 0.3), value: color)
        }
        .frame(height: 120)
    }
}

// MARK: - Preview
#Preview {
    VoiceRecorderView()
        .environmentObject(NotesManager())
        .environmentObject(AIService())
}
