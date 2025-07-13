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
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 0, count: 50)
    @State private var currentWaveIndex = 0
    
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
            WaveformView(
                amplitudes: waveformAmplitudes,
                isRecording: audioService.isRecording,
                audioLevel: CGFloat(audioService.audioLevel)
            )
            .frame(height: 100)
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
        waveformAmplitudes = Array(repeating: 0, count: 50)
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
        
        // Shift existing amplitudes
        waveformAmplitudes.removeFirst()
        waveformAmplitudes.append(CGFloat(audioService.audioLevel))
    }
}

// MARK: - Waveform Visualizer
struct WaveformView: View {
    let amplitudes: [CGFloat]
    let isRecording: Bool
    let audioLevel: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<amplitudes.count, id: \.self) { index in
                    WaveformBar(
                        amplitude: amplitudes[index],
                        isActive: isRecording && index == amplitudes.count - 1
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct WaveformBar: View {
    let amplitude: CGFloat
    let isActive: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isActive ? Color.red : Color.blue.opacity(0.7))
            .frame(width: 4)
            .frame(height: max(4, amplitude * 100))
            .animation(.easeOut(duration: 0.1), value: amplitude)
    }
}
