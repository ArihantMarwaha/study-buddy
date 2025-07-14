//
//  VoiceNoteCard.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI

struct VoiceNoteCard: View {
    let voiceNote: VoiceNote
    let isPlaying: Bool
    let onPlayToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with play button and metadata
            HStack {
                Button(action: onPlayToggle) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? Color.red : Color.blue)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(isPlaying ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPlaying)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDuration(voiceNote.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(voiceNote.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .symbolEffect(.pulse, options: .repeating)
                }
            }
            
            // Transcript section
            if let transcript = voiceNote.transcript {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Transcript")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    Text(transcript)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            } else {
                HStack {
                    Image(systemName: "text.bubble.slash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("No transcript available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isPlaying ? Color.red.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: isPlaying)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
}

#Preview {
    VoiceNoteCard(
        voiceNote: VoiceNote(
            audioData: Data(),
            duration: 120.0
        ),
        isPlaying: false,
        onPlayToggle: {}
    )
    .padding()
}
