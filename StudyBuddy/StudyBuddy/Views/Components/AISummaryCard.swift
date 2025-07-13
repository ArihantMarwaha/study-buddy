//
//  AISummaryCard.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI

struct AISummaryCard: View {
    let summary: String
    let keyPoints: [String]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Summary", systemImage: "brain")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Text(summary)
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                if !keyPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Points:")
                            .font(.subheadline.bold())
                        ForEach(keyPoints, id: \.self) { point in
                            Text(point)
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .glassEffect(in: .rect(cornerRadius: 12))
        )
    }
}
