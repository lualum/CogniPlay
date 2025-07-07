//
//  SpeechView.swift
//  CogniPlay
//
//  Created by Lucas Lum on 6/29/25.
//

import SwiftUI
import AVFoundation

// MARK: - Audio Recorder
class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var recordingTime = "00:00"
    @Published var audioData: Data?
    @Published var permissionGranted = false
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var startTime: Date?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupAudioSession()
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupAudioSession()
                    }
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startRecording() {
        guard !isRecording && permissionGranted else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording.wav")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000, // Optimal for wav2vec2
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            startTime = Date()
            startTimer()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        
        isRecording = false
        
        // Load audio data
        if let audioURL = audioRecorder?.url {
            audioData = try? Data(contentsOf: audioURL)
        }
    }
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let startTime = self.startTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            
            if elapsed >= 60 {
                self.stopRecording()
            } else {
                let minutes = Int(elapsed) / 60
                let seconds = Int(elapsed) % 60
                self.recordingTime = String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
}

// MARK: - Hugging Face Client (Simplified)
class HuggingFaceClient: ObservableObject {
    private let apiKey: String
    private let modelName = "cogniplayapp/wav2vec2-large-xls-r-300m-dm32"
    private let baseURL = "https://api-inference.huggingface.co/models/"
    
    @Published var isProcessing = false
    @Published var transcription = ""
    @Published var errorMessage = ""
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func processAudio(audioData: Data) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = ""
            transcription = ""
        }
        
        do {
            guard let url = URL(string: baseURL + modelName) else {
                await MainActor.run {
                    errorMessage = "Invalid URL"
                    isProcessing = false
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
            request.httpBody = audioData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    errorMessage = "Invalid response"
                    isProcessing = false
                }
                return
            }
            
            if httpResponse.statusCode != 200 {
                await MainActor.run {
                    errorMessage = "API Error: \(httpResponse.statusCode)"
                    isProcessing = false
                }
                return
            }
            
            if let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = result["text"] as? String {
                await MainActor.run {
                    transcription = text
                    isProcessing = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Failed to parse response"
                    isProcessing = false
                }
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }
}

// MARK: - Updated Speech View
struct SpeechView: View {
    @Binding var currentView: ContentView.AppView
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var huggingFaceClient = HuggingFaceClient(apiKey: "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") // Replace with your API key
    
    @State private var showingResults = false
    @State private var hasRecorded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Title
            VStack(spacing: 5) {
                Text("Speech")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Talk About Image")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
            .padding(.bottom, 30)
            
            // Image placeholder
            Rectangle()
                .fill(Color.white)
                .stroke(Color.black, lineWidth: 1)
                .frame(width: 280, height: 200)
                .overlay(
                    VStack {
                        Text("Image content would appear here")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("(Kitchen scene with family)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                )
                .padding(.bottom, 40)
            
            // Recording controls
            VStack(spacing: 20) {
                // Permission message
                if !audioRecorder.permissionGranted {
                    VStack(spacing: 10) {
                        Image(systemName: "mic.slash")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                        Text("Microphone permission is required")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("Please grant microphone access in Settings")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                } else {
                    // Microphone button
                    Button(action: {
                        if audioRecorder.isRecording {
                            audioRecorder.stopRecording()
                            hasRecorded = true
                        } else {
                            audioRecorder.startRecording()
                            hasRecorded = false
                            showingResults = false
                        }
                    }) {
                        Image(systemName: audioRecorder.isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(audioRecorder.isRecording ? Color.red : Color.black)
                            .clipShape(Circle())
                            .scaleEffect(audioRecorder.isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: audioRecorder.isRecording)
                    }
                    
                    // Timer
                    Text(audioRecorder.recordingTime + " / 1:00")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    // Process button (only show when recording is done)
                    if hasRecorded && !audioRecorder.isRecording {
                        Button(action: {
                            processAudio()
                        }) {
                            HStack {
                                if huggingFaceClient.isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Processing...")
                                } else {
                                    Text("Process Speech")
                                }
                            }
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(10)
                        }
                        .disabled(huggingFaceClient.isProcessing)
                        .padding(.horizontal, 30)
                    }
                }
                
                // Results display
                if showingResults {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Transcription:")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        if !huggingFaceClient.transcription.isEmpty {
                            ScrollView {
                                Text(huggingFaceClient.transcription)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .frame(maxHeight: 150)
                        }
                        
                        if !huggingFaceClient.errorMessage.isEmpty {
                            Text("Error: \(huggingFaceClient.errorMessage)")
                                .font(.body)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 30)
                }
                
                // Submit button (only show when we have results)
                if showingResults && !huggingFaceClient.transcription.isEmpty {
                    Button(action: {
                        currentView = .home
                    }) {
                        Text("Submit")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                }
            }
            
            Spacer()
        }
        .background(Color.white)
    }
    
    private func processAudio() {
        guard let audioData = audioRecorder.audioData else {
            huggingFaceClient.errorMessage = "No audio data available"
            return
        }
        
        Task {
            await huggingFaceClient.processAudio(audioData: audioData)
            await MainActor.run {
                showingResults = true
            }
        }
    }
}
