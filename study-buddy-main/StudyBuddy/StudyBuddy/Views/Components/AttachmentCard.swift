//
//  AttachmentCard.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers
import PDFKit
struct AttachmentCard: View {
    let attachment: Attachment
    var onExtractText: ((String) -> Void)? = nil
    var onDelete: (() -> Void)? = nil // Add onDelete closure
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            VStack(alignment: .trailing, spacing: 8) {
                GlassButton(action: openAttachment, label: {
                    Label("Open", systemImage: "arrow.up.doc")
                        .frame(minWidth: 70, maxWidth: 70, alignment: .center)
                })
                if onExtractText != nil {
                    GlassButton(action: extractTextAndSend, label: {
                        Label("Extract", systemImage: "doc.text.magnifyingglass")
                            .frame(minWidth: 70, maxWidth: 70, alignment: .center)
                    })
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
            // Delete button overlay
            if let onDelete = onDelete {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 1)
                    )
                    .padding([.top, .trailing], 10)
                }
            }
        }
    }
    
    private func iconForFileType(_ type: UTType) -> String {
        if type.conforms(to: .pdf) { return "doc.fill" }
        if type.conforms(to: .image) { return "photo.fill" }
        if type.conforms(to: .audio) { return "music.note" }
        return "doc.fill"
    }
    
    private func openAttachment() {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(attachment.fileName)
        do {
            try attachment.data.write(to: tempURL)
            NSWorkspace.shared.open(tempURL)
        } catch {
            print("Failed to open attachment: \(error)")
        }
    }
    
    private func extractTextAndSend() {
        var extractedText = ""
        if attachment.fileType.conforms(to: .plainText) {
            extractedText = String(data: attachment.data, encoding: .utf8) ?? "(Unable to decode text)"
        } else if attachment.fileType.conforms(to: .pdf) {
            if let pdfDoc = PDFDocument(data: attachment.data) {
                for i in 0..<pdfDoc.pageCount {
                    if let page = pdfDoc.page(at: i), let pageText = page.string {
                        extractedText += pageText + "\n"
                    }
                }
            } else {
                extractedText = "(Unable to extract text from PDF)"
            }
        } else {
            extractedText = "(Text extraction not supported for this file type)"
        }
        onExtractText?(extractedText)
    }
}

// Glass effect button style
struct GlassButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    var body: some View {
        Button(action: action) {
            label()
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                )
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
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
