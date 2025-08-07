// import AVFoundation
// import Foundation
// import Speech

// // MARK: - API Models for Alzheimer Detection API
// struct TrialData: Codable {
//   let utterance: String
//   let duration: Double?

//   init(utterance: String, duration: Double? = nil) {
//     self.utterance = utterance
//     self.duration = duration
//   }
// }

// struct AlzheimerPredictionRequest: Codable {
//   let trial_data: [TrialData]
// }

// struct AlzheimerPredictionResponse: Codable {
//   let probability: Double
//   let prediction: Int
//   let confidence: String
// }

// struct APIError: Codable {
//   let error: String
//   let message: String?
// }

// // MARK: - Error Types
// enum TranscriptionError: Error, LocalizedError {
//   case invalidAPIKey
//   case invalidAudioFile
//   case invalidResponse
//   case invalidRequest
//   case apiError(String)
//   case networkError(String)

//   var errorDescription: String? {
//     switch self {
//     case .invalidAPIKey:
//       return "Invalid or missing API key"
//     case .invalidAudioFile:
//       return "Could not read audio file"
//     case .invalidResponse:
//       return "Invalid response from API"
//     case .invalidRequest:
//       return "Could not create request"
//     case .apiError(let message):
//       return "API Error: \(message)"
//     case .networkError(let message):
//       return "Network Error: \(message)"
//     }
//   }
// }

// // MARK: - Audio Recorder Class
// class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
//   @Published var isRecording = false
//   @Published var hasRecording = false

//   private var audioRecorder: AVAudioRecorder?
//   var audioURL: URL?

//   override init() {
//     super.init()
//     setupAudioSession()
//   }

//   private func setupAudioSession() {
//     do {
//       let session = AVAudioSession.sharedInstance()

//       // Check if recording is available
//       guard session.isInputAvailable else {
//         print("Audio input not available")
//         return
//       }

//       try session.setCategory(
//         .playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
//       try session.setActive(true, options: .notifyOthersOnDeactivation)

//       print("Audio session setup successful")
//     } catch {
//       print("Failed to setup audio session: \(error.localizedDescription)")
//     }
//   }

//   // Also add this method to check permissions before recording
//   func checkPermissions() -> Bool {
//     let audioStatus = AVAudioSession.sharedInstance().recordPermission
//     let speechStatus = SFSpeechRecognizer.authorizationStatus()

//     return audioStatus == .granted && speechStatus == .authorized
//   }

//   func requestPermission() {
//     // Always use AVAudioSession for recording permission
//     AVAudioSession.sharedInstance().requestRecordPermission { granted in
//       DispatchQueue.main.async {
//         if !granted {
//           print("Audio recording permission denied")
//         }
//       }
//     }

//     // Request speech recognition permission
//     SFSpeechRecognizer.requestAuthorization { authStatus in
//       DispatchQueue.main.async {
//         if authStatus != .authorized {
//           print("Speech recognition permission denied")
//         }
//       }
//     }
//   }

//   func startRecording() {
//     let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//     let audioFilename = documentsPath.appendingPathComponent("recording.wav")

//     let settings =
//       [
//         AVFormatIDKey: Int(kAudioFormatLinearPCM),
//         AVSampleRateKey: 16000,
//         AVNumberOfChannelsKey: 1,
//         AVLinearPCMBitDepthKey: 16,
//         AVLinearPCMIsBigEndianKey: false,
//         AVLinearPCMIsFloatKey: false,
//         AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
//       ] as [String: Any]

//     do {
//       audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
//       audioRecorder?.delegate = self
//       audioRecorder?.record()

//       self.audioURL = audioFilename
//       self.isRecording = true
//       self.hasRecording = false
//     } catch {
//       print("Could not start recording: \(error.localizedDescription)")
//     }
//   }

//   func stopRecording() {
//     audioRecorder?.stop()
//     isRecording = false
//     hasRecording = audioURL != nil
//   }

//   func deleteCurrentRecording() {
//     guard let url = audioURL else { return }

//     do {
//       if FileManager.default.fileExists(atPath: url.path) {
//         try FileManager.default.removeItem(at: url)
//         print("Audio file deleted successfully: \(url.path)")
//       }
//     } catch {
//       print("Failed to delete audio file: \(error.localizedDescription)")
//     }

//     audioURL = nil
//     hasRecording = false
//   }

//   // MARK: - AVAudioRecorderDelegate
//   func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
//     if flag {
//       hasRecording = true
//     }
//   }

//   // MARK: - Helper Functions
//   func getAudioFileInfo() -> String? {
//     guard let url = audioURL else { return nil }

//     do {
//       guard FileManager.default.fileExists(atPath: url.path) else {
//         return "Audio file does not exist"
//       }

//       let audioFile = try AVAudioFile(forReading: url)
//       let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
//       let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
//       let fileSize = attributes[.size] as? Int64 ?? 0

//       return """
//         Audio File Info:
//         - Duration: \(String(format: "%.2f", duration)) seconds
//         - File Size: \(fileSize) bytes
//         - Sample Rate: \(audioFile.fileFormat.sampleRate) Hz
//         - Channels: \(audioFile.fileFormat.channelCount)
//         """
//     } catch {
//       return "Error reading audio file: \(error.localizedDescription)"
//     }
//   }
// }

// // MARK: - Alzheimer Detection Service
// class AlzheimerDetectionService: ObservableObject {
//   private let baseURL = "https://cogniplayapp-alzheimer-detection-api.hf.space"

//   // MARK: - Main Analysis Functions (Simplified)
//   func analyzeUtterances(_ utterances: [TrialData]) async throws -> AlzheimerPredictionResponse {
//     guard let url = URL(string: baseURL + "/predict") else {
//       throw TranscriptionError.invalidRequest
//     }

//     let requestData = AlzheimerPredictionRequest(trial_data: utterances)

//     var request = URLRequest(url: url)
//     request.httpMethod = "POST"
//     request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//     request.timeoutInterval = 60.0

//     do {
//       let jsonData = try JSONEncoder().encode(requestData)
//       request.httpBody = jsonData
//     } catch {
//       throw TranscriptionError.invalidRequest
//     }

//     do {
//       let (data, response) = try await URLSession.shared.data(for: request)

//       guard let httpResponse = response as? HTTPURLResponse else {
//         throw TranscriptionError.invalidResponse
//       }

//       guard 200...299 ~= httpResponse.statusCode else {
//         throw TranscriptionError.apiError("HTTP Error: \(httpResponse.statusCode)")
//       }

//       let predictionResponse = try JSONDecoder().decode(
//         AlzheimerPredictionResponse.self, from: data)
//       return predictionResponse

//     } catch {
//       if error is TranscriptionError {
//         throw error
//       } else {
//         throw TranscriptionError.networkError(error.localizedDescription)
//       }
//     }
//   }

//   // MARK: - Convenience Methods
//   func analyzeSingleUtterance(_ utterance: String, duration: Double? = nil) async throws
//     -> AlzheimerPredictionResponse
//   {
//     let trialData = [TrialData(utterance: utterance, duration: duration)]
//     return try await analyzeUtterances(trialData)
//   }

//   func analyzeAudioForAlzheimers(audioURL: URL, recordingDuration: Double) async throws
//     -> AlzheimerPredictionResponse
//   {
//     // First, transcribe the audio
//     let transcription = try await transcribeAudio(audioURL: audioURL)

//     // Then analyze the transcription for Alzheimer's
//     return try await analyzeSingleUtterance(transcription, duration: recordingDuration)
//   }

//   // MARK: - API Validation
//   func validateAPIConnection() async throws -> Bool {
//     let testData = [TrialData(utterance: "Hello world", duration: 1.0)]

//     do {
//       _ = try await analyzeUtterances(testData)
//       return true
//     } catch {
//       print("API validation error: \(error)")
//       return false
//     }
//   }

//   // MARK: - Audio Transcription using iOS Speech Recognition
//   func transcribeAudio(audioURL: URL) async throws -> String {
//     return try await withCheckedThrowingContinuation { continuation in
//       // Check speech recognition authorization
//       SFSpeechRecognizer.requestAuthorization { authStatus in
//         guard authStatus == .authorized else {
//           continuation.resume(
//             throwing: TranscriptionError.apiError("Speech recognition not authorized"))
//           return
//         }

//         // Create speech recognizer
//         guard let speechRecognizer = SFSpeechRecognizer() else {
//           continuation.resume(
//             throwing: TranscriptionError.apiError("Speech recognizer not available"))
//           return
//         }

//         guard speechRecognizer.isAvailable else {
//           continuation.resume(
//             throwing: TranscriptionError.apiError("Speech recognizer not available"))
//           return
//         }

//         // Create recognition request
//         let request = SFSpeechURLRecognitionRequest(url: audioURL)
//         request.shouldReportPartialResults = false

//         // Perform recognition
//         speechRecognizer.recognitionTask(with: request) { result, error in
//           if let error = error {
//             continuation.resume(
//               throwing: TranscriptionError.networkError(error.localizedDescription))
//             return
//           }

//           guard let result = result, result.isFinal else {
//             return
//           }

//           let transcription = result.bestTranscription.formattedString.trimmingCharacters(
//             in: .whitespacesAndNewlines)
//           continuation.resume(returning: transcription)
//         }
//       }
//     }
//   }

//   // MARK: - Speech Recognition Permission
//   func requestSpeechRecognitionPermission() async -> Bool {
//     return await withCheckedContinuation { continuation in
//       SFSpeechRecognizer.requestAuthorization { authStatus in
//         continuation.resume(returning: authStatus == .authorized)
//       }
//     }
//   }
// }

// // MARK: - Helper function to create utterances easily
// func createTrialData(_ text: String, duration: Double? = nil) -> TrialData {
//   return TrialData(utterance: text, duration: duration)
// }
