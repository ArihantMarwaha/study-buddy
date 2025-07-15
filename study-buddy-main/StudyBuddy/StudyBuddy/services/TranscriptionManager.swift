import Foundation
import Speech
import SwiftUI
internal import Combine

@MainActor
class TranscriptionManager: ObservableObject {
    @Published var transcription: String?
    @Published var isTranscribing = false

    private let speechRecognizer = SFSpeechRecognizer()

    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                // You can handle status if needed
            }
        }
    }

    func transcribeAudio(url: URL) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognition not available")
            return
        }
        isTranscribing = true
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.transcription = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.isTranscribing = false
                    }
                } else if let error = error {
                    print("Transcription error: \(error)")
                    self.isTranscribing = false
                    self.transcription = "Transcription failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func clearTranscription() {
        transcription = nil
        isTranscribing = false
    }
} 
