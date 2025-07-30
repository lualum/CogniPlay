import AVFoundation
import Foundation
import SwiftUI

// MARK: - Response Models
struct DementiaDetectionResponse: Codable {
  let predicted_label: String
  let confidence: Double
  let all_scores: [ScoreItem]
}

struct ScoreItem: Codable {
  let label: String
  let score: Double
}

// MARK: - Audio Recorder Class
class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
  @Published var isRecording = false
  @Published var hasRecording = false

  private var audioRecorder: AVAudioRecorder?
  var audioURL: URL?

  override init() {
    super.init()
    setupAudioSession()
  }

  private func setupAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .default)
      try session.setActive(true)
    } catch {
      print("Failed to setup audio session: \(error.localizedDescription)")
    }
  }

  func requestPermission() {
    if #available(iOS 17.0, *) {
      AVAudioApplication.requestRecordPermission { granted in
        DispatchQueue.main.async {
          if !granted {
            print("Audio recording permission denied")
          }
        }
      }
    } else {
      // Fallback for iOS 16 and earlier
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async {
          if !granted {
            print("Audio recording permission denied")
          }
        }
      }
    }
  }

  func startRecording() {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let audioFilename = documentsPath.appendingPathComponent("recording.wav")

    let settings =
      [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16000,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
      ] as [String: Any]

    do {
      audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      audioRecorder?.delegate = self
      audioRecorder?.record()

      self.audioURL = audioFilename
      self.isRecording = true
      self.hasRecording = false
    } catch {
      print("Could not start recording: \(error.localizedDescription)")
    }
  }

  func stopRecording() {
    audioRecorder?.stop()
    isRecording = false
    hasRecording = audioURL != nil
  }

  // MARK: - AVAudioRecorderDelegate
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      hasRecording = true
    }
  }
}

// MARK: - Enhanced Hugging Face Service Class
class HuggingFaceService: ObservableObject {
  private let apiKey = "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"
  private let apiURL = "https://wpa4x28892l5a6i5.us-east-1.aws.endpoints.huggingface.cloud"

  func validateAPIKey() async throws -> Bool {
    // Test the API connection with a simple request
    guard !apiKey.isEmpty else {
      return false
    }

    // Create a minimal test request to check if the endpoint is accessible
    var request = URLRequest(url: URL(string: apiURL)!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Send a minimal test payload
    let testPayload = [
      "inputs": [
        "audio": "dGVzdA=="  // Base64 for "test"
      ]
    ]

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: testPayload)
      request.httpBody = jsonData

      let (_, response) = try await URLSession.shared.data(for: request)

      if let httpResponse = response as? HTTPURLResponse {
        print("API Validation Status Code: \(httpResponse.statusCode)")
        // Accept various status codes that indicate the API is accessible
        // 200: Success, 400: Bad request but API is working, 422: Validation error but API is accessible
        return httpResponse.statusCode == 200 || httpResponse.statusCode == 400
          || httpResponse.statusCode == 422
      }

      return false
    } catch {
      print("API Validation Error: \(error)")
      return false
    }
  }

  func detectDementia(audioURL: URL) async throws -> DementiaDetectionResponse {
    guard !apiKey.isEmpty else {
      throw TranscriptionError.invalidAPIKey
    }

    guard let audioData = try? Data(contentsOf: audioURL) else {
      throw TranscriptionError.invalidAudioFile
    }

    // Convert audio data to base64
    let base64AudioData = audioData.base64EncodedString()

    // Create request payload
    let requestBody = [
      "inputs": [
        "audio": base64AudioData
      ]
    ]

    guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
      throw TranscriptionError.invalidRequest
    }

    var request = URLRequest(url: URL(string: apiURL)!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw TranscriptionError.invalidResponse
      }

      print("API Response Status Code: \(httpResponse.statusCode)")

      if httpResponse.statusCode != 200 {
        // Try to parse error message
        if let errorString = String(data: data, encoding: .utf8) {
          print("API Error Response: \(errorString)")
        }
        throw TranscriptionError.apiError("API returned status code: \(httpResponse.statusCode)")
      }

      // Print raw response for debugging
      if let responseString = String(data: data, encoding: .utf8) {
        print("Raw API Response: \(responseString)")
      }

      // Parse the response
      do {
        // The API returns an array, so we need to decode it as such
        let responses = try JSONDecoder().decode([DementiaDetectionResponse].self, from: data)

        guard let firstResponse = responses.first else {
          throw TranscriptionError.invalidResponse
        }

        return firstResponse

      } catch let decodingError {
        print("JSON Decoding Error: \(decodingError)")
        throw TranscriptionError.invalidResponse
      }

    } catch {
      print("Network Error: \(error)")
      throw TranscriptionError.networkError(error.localizedDescription)
    }
  }

  // Keep the original transcription method as backup
  func transcribeAudio(audioURL: URL) async throws -> String {
    guard !apiKey.isEmpty else {
      throw TranscriptionError.invalidAPIKey
    }

    guard let audioData = try? Data(contentsOf: audioURL) else {
      throw TranscriptionError.invalidAudioFile
    }

    let whisperURL = "https://api-inference.huggingface.co/models/openai/whisper-base"
    var request = URLRequest(url: URL(string: whisperURL)!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
    request.httpBody = audioData

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw TranscriptionError.invalidResponse
      }

      if httpResponse.statusCode != 200 {
        throw TranscriptionError.apiError("API returned status code: \(httpResponse.statusCode)")
      }

      if let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let text = result["text"] as? String
      {
        return text
      } else {
        // Try to parse as direct string response
        if let text = String(data: data, encoding: .utf8) {
          return text
        } else {
          throw TranscriptionError.invalidResponse
        }
      }
    } catch {
      throw TranscriptionError.networkError(error.localizedDescription)
    }
  }
}

// MARK: - Updated Error Types
enum TranscriptionError: Error, LocalizedError {
  case invalidAPIKey
  case invalidAudioFile
  case invalidResponse
  case invalidRequest
  case apiError(String)
  case networkError(String)

  var errorDescription: String? {
    switch self {
    case .invalidAPIKey:
      return "Invalid or missing API key"
    case .invalidAudioFile:
      return "Could not read audio file"
    case .invalidResponse:
      return "Invalid response from API"
    case .invalidRequest:
      return "Could not create request"
    case .apiError(let message):
      return "API Error: \(message)"
    case .networkError(let message):
      return "Network Error: \(message)"
    }
  }
}

// MARK: - Updated Speech View
struct SpeechView: View {
  @Binding var currentView: ContentView.AppView
  @StateObject private var audioRecorder = AudioRecorder()
  @StateObject private var huggingFaceService = HuggingFaceService()
  @State private var recordingTime = "00:00"
  @State private var timer: Timer?
  @State private var recordingDuration: TimeInterval = 0
  @State private var transcription = ""
  @State private var dementiaResult: DementiaDetectionResponse?
  @State private var isProcessing = false
  @State private var errorMessage = ""
  @State private var showError = false
  @State private var apiKeyValid = false
  @State private var processingMode: ProcessingMode = .dementia

  enum ProcessingMode {
    case dementia
    case transcription
  }

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // Title
      VStack(spacing: 5) {
        Text("Speech Analysis")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("Dementia Detection")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.primary)
      }
      .padding(.bottom, 30)

      // Image placeholder
      Rectangle()
        .fill(Color(.systemBackground))
        .stroke(Color.primary, lineWidth: 1)
        .frame(width: 280, height: 200)
        .overlay(
          VStack {
            Image(systemName: "brain.head.profile")
              .font(.system(size: 40))
              .foregroundColor(.blue)
            Text("Voice Analysis")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("(Dementia Detection)")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        )
        .padding(.bottom, 20)

      // Processing mode selector
      Picker("Processing Mode", selection: $processingMode) {
        Text("Dementia Detection").tag(ProcessingMode.dementia)
        Text("Transcription").tag(ProcessingMode.transcription)
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding(.horizontal, 20)
      .padding(.bottom, 20)

      // Error display
      if showError {
        VStack(alignment: .leading, spacing: 5) {
          Text("Error:")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.red)

          Text(errorMessage)
            .font(.body)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.red)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }

      // Results display
      if let result = dementiaResult {
        VStack(alignment: .leading, spacing: 10) {
          Text("Dementia Detection Result:")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.blue)

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Prediction:")
                .fontWeight(.medium)
              Text(result.predicted_label.capitalized)
                .fontWeight(.bold)
                .foregroundColor(result.predicted_label.lowercased() == "dementia" ? .red : .green)
            }

            HStack {
              Text("Confidence:")
                .fontWeight(.medium)
              Text("\(String(format: "%.1f", result.confidence * 100))%")
                .fontWeight(.bold)
            }

            Text("All Scores:")
              .fontWeight(.medium)
              .padding(.top, 5)

            ForEach(result.all_scores, id: \.label) { score in
              HStack {
                Text("• \(score.label.capitalized):")
                Spacer()
                Text("\(String(format: "%.1f", score.score * 100))%")
                  .fontWeight(.medium)
              }
              .padding(.leading, 10)
            }
          }
          .padding()
          .background(Color.blue.opacity(0.1))
          .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }

      // Transcription display
      if !transcription.isEmpty {
        VStack(alignment: .leading, spacing: 5) {
          Text("Transcription:")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.green)

          Text(transcription)
            .font(.body)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }

      // Recording controls
      VStack(spacing: 20) {
        // Microphone button
        Button(action: {
          if audioRecorder.isRecording {
            stopRecording()
          } else {
            startRecording()
          }
        }) {
          Image(systemName: audioRecorder.isRecording ? "mic.fill" : "mic")
            .font(.system(size: 40))
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(audioRecorder.isRecording ? Color.red : Color.blue)
            .clipShape(Circle())
            .scaleEffect(audioRecorder.isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: audioRecorder.isRecording)
        }
        .disabled(isProcessing)

        // Timer
        Text(recordingTime)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(audioRecorder.isRecording ? .red : .primary)

        // Processing indicator
        if isProcessing {
          HStack {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
            Text("Processing audio...")
              .font(.body)
              .foregroundColor(.secondary)
          }
        }

        // API Status indicator
        HStack {
          Circle()
            .fill(apiKeyValid ? Color.green : Color.red)
            .frame(width: 8, height: 8)
          Text(apiKeyValid ? "API Connected" : "API Disconnected")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        // Submit button
        Button(action: {
          if audioRecorder.hasRecording {
            processAudio()
          }
        }) {
          Text(isProcessing ? "Processing..." : "Analyze Audio")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
              audioRecorder.hasRecording && !isProcessing ? Color.blue : Color.gray.opacity(0.7)
            )
            .cornerRadius(10)
        }
        .padding(.horizontal, 30)
        .disabled(!audioRecorder.hasRecording || isProcessing)

        // Test API button
        Button(action: {
          testAPIConnection()
        }) {
          Text("Test API Connection")
            .font(.body)
            .foregroundColor(.blue)
        }
        .disabled(isProcessing)
      }

      Spacer()
    }
    .background(Color(.systemBackground))
    .onAppear {
      requestPermissionsAndSetup()
    }
    .onDisappear {
      cleanup()
    }
  }

  // MARK: - Setup and Cleanup
  private func requestPermissionsAndSetup() {
    audioRecorder.requestPermission()
    testAPIConnection()
  }

  private func cleanup() {
    stopRecording()
    timer?.invalidate()
    timer = nil
  }

  // MARK: - Recording Functions
  private func startRecording() {
    // Reset states
    recordingDuration = 0
    updateTimer()
    transcription = ""
    dementiaResult = nil
    errorMessage = ""
    showError = false

    // Start recording
    audioRecorder.startRecording()

    // Start timer
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      recordingDuration += 1
      updateTimer()
    }
  }

  private func stopRecording() {
    timer?.invalidate()
    timer = nil
    audioRecorder.stopRecording()
  }

  private func updateTimer() {
    let minutes = Int(recordingDuration) / 60
    let seconds = Int(recordingDuration) % 60
    recordingTime = String(format: "%02d:%02d", minutes, seconds)
  }

  // MARK: - API Functions
  private func testAPIConnection() {
    Task {
      do {
        let isValid = try await huggingFaceService.validateAPIKey()
        await MainActor.run {
          self.apiKeyValid = isValid
          if !isValid {
            self.showError = true
            self.errorMessage = "API key validation failed. Please check your Hugging Face API key."
          }
        }
      } catch {
        await MainActor.run {
          self.apiKeyValid = false
          self.showError = true
          self.errorMessage = "Failed to connect to Hugging Face API: \(error.localizedDescription)"
        }
      }
    }
  }

  private func processAudio() {
    guard let audioURL = audioRecorder.audioURL else {
      showError = true
      errorMessage = "No audio file found"
      return
    }

    print("Processing audio file: \(audioURL.path)")
    printAudioFileInfo(url: audioURL)

    isProcessing = true
    showError = false
    errorMessage = ""

    if processingMode == .dementia {
      processDementiaDetection(audioURL: audioURL)
    } else {
      processTranscription(audioURL: audioURL)
    }
  }

  private func processDementiaDetection(audioURL: URL) {
    Task {
      do {
        let result = try await huggingFaceService.detectDementia(audioURL: audioURL)
        await MainActor.run {
          print("DEMENTIA DETECTION RESULT: \(result)")
          self.dementiaResult = result
          self.transcription = ""  // Clear transcription
          self.isProcessing = false
          self.showError = false

          // Clean up the audio file after processing
          self.deleteAudioFile(url: audioURL)
        }
      } catch {
        await MainActor.run {
          print("DEMENTIA DETECTION ERROR: \(error.localizedDescription)")
          self.isProcessing = false
          self.showError = true
          self.errorMessage = "Dementia detection failed: \(error.localizedDescription)"

          // Clean up the audio file even on error
          self.deleteAudioFile(url: audioURL)
        }
      }
    }
  }

  private func processTranscription(audioURL: URL) {
    Task {
      do {
        let result = try await huggingFaceService.transcribeAudio(audioURL: audioURL)
        await MainActor.run {
          print("TRANSCRIPTION RESULT: \(result)")
          self.transcription = result
          self.dementiaResult = nil  // Clear dementia result
          self.isProcessing = false
          self.showError = false

          // Clean up the audio file after processing
          self.deleteAudioFile(url: audioURL)
        }
      } catch {
        await MainActor.run {
          print("TRANSCRIPTION ERROR: \(error.localizedDescription)")
          self.isProcessing = false
          self.showError = true
          self.errorMessage = "Transcription failed: \(error.localizedDescription)"

          // Clean up the audio file even on error
          self.deleteAudioFile(url: audioURL)
        }
      }
    }
  }

  // MARK: - Helper Functions
  private func deleteAudioFile(url: URL) {
    do {
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
        print("Audio file deleted successfully: \(url.path)")
      }
    } catch {
      print("Failed to delete audio file: \(error.localizedDescription)")
    }
  }

  private func printAudioFileInfo(url: URL) {
    do {
      guard FileManager.default.fileExists(atPath: url.path) else {
        print("Audio file does not exist at path: \(url.path)")
        return
      }

      let audioFile = try AVAudioFile(forReading: url)
      let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
      let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
      let fileSize = attributes[.size] as? Int64 ?? 0

      print("Audio File Info:")
      print("- File Path: \(url.path)")
      print("- Duration: \(String(format: "%.2f", duration)) seconds")
      print("- File Size: \(fileSize) bytes")
      print("- Sample Rate: \(audioFile.fileFormat.sampleRate) Hz")
      print("- Channels: \(audioFile.fileFormat.channelCount)")
    } catch {
      print("Error reading audio file info: \(error.localizedDescription)")
    }
  }
}
