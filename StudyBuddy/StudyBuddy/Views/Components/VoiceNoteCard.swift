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
        HStack {
            Button(action: onPlayToggle) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading) {
                Text("Duration: \(formatDuration(voiceNote.duration))")
                    .font(.caption)
                if let transcript = voiceNote.transcript {
                    Text(transcript)
                        .font(.callout)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(voiceNote.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
}
