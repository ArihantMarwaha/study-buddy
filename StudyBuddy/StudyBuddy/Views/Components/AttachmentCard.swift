//
//  AttachmentCard.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers
struct AttachmentCard: View {
    let attachment: Attachment
    
    var body: some View {
        HStack {
            Image(systemName: iconForFileType(attachment.fileType))
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading) {
                Text(attachment.fileName)
                    .font(.callout)
                    .lineLimit(1)
                Text("\(ByteCountFormatter.string(fromByteCount: Int64(attachment.data.count), countStyle: .file))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Open") {
                // Open attachment
            }
            .buttonStyle(.link)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func iconForFileType(_ type: UTType) -> String {
        if type.conforms(to: .pdf) { return "doc.fill" }
        if type.conforms(to: .image) { return "photo.fill" }
        if type.conforms(to: .audio) { return "music.note" }
        return "doc.fill"
    }
}

#Preview {
    AttachmentCard(
        attachment: Attachment(
            fileName: "sample-document.pdf",
            fileType: .pdf,
            data: Data()
        )
    )
    .padding()
}

#Preview {
    AttachmentCard(
        attachment: Attachment(
            fileName: "sample-document.pdf",
            fileType: .pdf,
            data: Data()
        )
    )
    .padding()
}
