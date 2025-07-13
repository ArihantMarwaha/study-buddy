//
//  AudioService.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import Foundation
import SwiftUI
import AVFoundation
internal import Combine

@MainActor
class AudioService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var hasRecordingPermission = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    override init() {
        super.init()
        #if os(iOS)
        setupAudioSession()
        checkRecordingPermission()
        #elseif os(macOS)
        hasRecordingPermission = true
        #endif
    }
    
    // MARK: - Setup
    #if os(iOS)
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    #else
    private func setupAudioSession() {}
    #endif
    
    func checkRecordingPermission() {
        #if os(iOS)
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            hasRecordingPermission = true
        case .denied:
            hasRecordingPermission = false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasRecordingPermission = granted
                }
            }
        @unknown default:
            hasRecordingPermission = false
        }
        #elseif os(macOS)
        hasRecordingPermission = true
        #endif
    }
    
    // MARK: - Recording
    func startRecording() -> URL? {
        #if os(iOS)
        guard hasRecordingPermission else {
            print("No recording permission")
            return nil
        }
        #endif
        
        let recordingURL = getRecordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecording = true
            recordingStartTime = Date()
            startMetering()
            
            return recordingURL
        } catch {
            print("Failed to start recording: \(error)")
            return nil
        }
    }
    
    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard isRecording else { return nil }
        
        audioRecorder?.stop()
        isRecording = false
        stopMetering()
        
        guard let url = audioRecorder?.url,
              let startTime = recordingStartTime else { return nil }
        
        let duration = Date().timeIntervalSince(startTime)
        audioRecorder = nil
        recordingStartTime = nil
        
        return (url, duration)
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        stopMetering()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        startMetering()
    }
    
    // MARK: - Playback
    func playAudio(from data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    // MARK: - Metering
    private func startMetering() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await MainActor.run {
                    self?.updateMeters()
                }
            }
        }
    }
    
    private func stopMetering() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioLevel = 0
        recordingTime = 0
    }
    
    private func updateMeters() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10, level / 20) // Convert dB to linear scale
        
        DispatchQueue.main.async {
            self.audioLevel = max(0, min(1, normalizedLevel))
            if let startTime = self.recordingStartTime {
                self.recordingTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getRecordingURL() -> URL {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = "recording_\(Date().timeIntervalSince1970).m4a"
        return documentPath.appendingPathComponent(audioFilename)
    }
    
    func loadAudioData(from url: URL) -> Data? {
        try? Data(contentsOf: url)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Handle playback completion
    }
}

