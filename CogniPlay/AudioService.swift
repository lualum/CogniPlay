import AVFoundation
import Foundation

// MARK: - API Models for Alzheimer Detection API
struct TrialData: Codable {
  let utterance: String
  let duration: Double?

  init(utterance: String, duration: Double? = nil) {
    self.utterance = utterance
    self.duration = duration
  }
}

struct AlzheimerPredictionRequest: Codable {
  let trialData: [TrialData]

  enum CodingKeys: String, CodingKey {
    case trialData = "trial_data"
  }
}

struct AlzheimerPredictionResponse: Codable {
  let probability: Double
  let prediction: Int
  let confidence: String
}

struct APIError: Codable {
  let error: String
  let message: String?
}

// MARK: - Error Types
enum AlzheimerDetectionError: Error, LocalizedError {
  case invalidRequest
  case invalidResponse
  case apiError(String)
  case networkError(String)

  var errorDescription: String? {
    switch self {
    case .invalidRequest:
      return "Could not create request"
    case .invalidResponse:
      return "Invalid response from API"
    case .apiError(let message):
      return "API Error: \(message)"
    case .networkError(let message):
      return "Network Error: \(message)"
    }
  }
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

  func deleteCurrentRecording() {
    guard let url = audioURL else { return }

    do {
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
        print("Audio file deleted successfully: \(url.path)")
      }
    } catch {
      print("Failed to delete audio file: \(error.localizedDescription)")
    }

    audioURL = nil
    hasRecording = false
  }

  // MARK: - AVAudioRecorderDelegate
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      hasRecording = true
    }
  }

  // MARK: - Helper Functions
  func getAudioFileInfo() -> String? {
    guard let url = audioURL else { return nil }

    do {
      guard FileManager.default.fileExists(atPath: url.path) else {
        return "Audio file does not exist"
      }

      let audioFile = try AVAudioFile(forReading: url)
      let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
      let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
      let fileSize = attributes[.size] as? Int64 ?? 0

      return """
        Audio File Info:
        - Duration: \(String(format: "%.2f", duration)) seconds
        - File Size: \(fileSize) bytes
        - Sample Rate: \(audioFile.fileFormat.sampleRate) Hz
        - Channels: \(audioFile.fileFormat.channelCount)
        """
    } catch {
      return "Error reading audio file: \(error.localizedDescription)"
    }
  }
}

// MARK: - Alzheimer Detection Service
class AlzheimerDetectionService: ObservableObject {
  private let baseURL = "https://cogniplayapp-alzheimer-detection-api.hf.space"
  private let session: URLSession

  init() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 60.0
    config.timeoutIntervalForResource = 120.0
    self.session = URLSession(configuration: config)
  }

  // MARK: - API Validation
  func validateAPIConnection() async throws -> Bool {
    guard let url = URL(string: baseURL + "/predict") else {
      throw AlzheimerDetectionError.invalidRequest
    }

    let testRequest = AlzheimerPredictionRequest(
      trialData: [TrialData(utterance: "Hello world", duration: 1.0)]
    )

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.timeoutInterval = 10.0

    do {
      urlRequest.httpBody = try JSONEncoder().encode(testRequest)
      let (_, response) = try await session.data(for: urlRequest)

      if let httpResponse = response as? HTTPURLResponse {
        return httpResponse.statusCode == 200 || httpResponse.statusCode == 400
          || httpResponse.statusCode == 422
      }
      return false
    } catch {
      print("API validation error: \(error)")
      return false
    }
  }

  // MARK: - Main Analysis Function (for text input)
  func analyzeUtteranceForAlzheimers(utterance: String, duration: Double? = nil) async throws
    -> AlzheimerPredictionResponse
  {
    guard let url = URL(string: baseURL + "/predict") else {
      throw AlzheimerDetectionError.invalidRequest
    }

    let request = AlzheimerPredictionRequest(
      trialData: [TrialData(utterance: utterance, duration: duration)]
    )

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      urlRequest.httpBody = try JSONEncoder().encode(request)
    } catch {
      throw AlzheimerDetectionError.invalidRequest
    }

    do {
      let (data, response) = try await session.data(for: urlRequest)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw AlzheimerDetectionError.invalidResponse
      }

      print("Alzheimer API Response Status: \(httpResponse.statusCode)")

      if let responseString = String(data: data, encoding: .utf8) {
        print("Alzheimer API Response: \(responseString)")
      }

      guard 200...299 ~= httpResponse.statusCode else {
        if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
          throw AlzheimerDetectionError.apiError(
            errorResponse.error
              + (errorResponse.message != nil ? ": \(errorResponse.message!)" : ""))
        } else {
          throw AlzheimerDetectionError.apiError(
            "API returned status code: \(httpResponse.statusCode)")
        }
      }

      do {
        let predictionResponse = try JSONDecoder().decode(
          AlzheimerPredictionResponse.self, from: data)
        return predictionResponse
      } catch {
        print("JSON Decoding Error: \(error)")
        throw AlzheimerDetectionError.invalidResponse
      }

    } catch {
      if error is AlzheimerDetectionError {
        throw error
      } else {
        throw AlzheimerDetectionError.networkError(error.localizedDescription)
      }
    }
  }

  // MARK: - Multiple Utterances Analysis
  func analyzeMultipleUtterances(_ utterances: [TrialData]) async throws
    -> AlzheimerPredictionResponse
  {
    guard let url = URL(string: baseURL + "/predict") else {
      throw AlzheimerDetectionError.invalidRequest
    }

    let request = AlzheimerPredictionRequest(trialData: utterances)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      urlRequest.httpBody = try JSONEncoder().encode(request)
    } catch {
      throw AlzheimerDetectionError.invalidRequest
    }

    do {
      let (data, response) = try await session.data(for: urlRequest)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw AlzheimerDetectionError.invalidResponse
      }

      print("Alzheimer API Response Status: \(httpResponse.statusCode)")

      if let responseString = String(data: data, encoding: .utf8) {
        print("Alzheimer API Response: \(responseString)")
      }

      guard 200...299 ~= httpResponse.statusCode else {
        if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
          throw AlzheimerDetectionError.apiError(
            errorResponse.error
              + (errorResponse.message != nil ? ": \(errorResponse.message!)" : ""))
        } else {
          throw AlzheimerDetectionError.apiError(
            "API returned status code: \(httpResponse.statusCode)")
        }
      }

      do {
        let predictionResponse = try JSONDecoder().decode(
          AlzheimerPredictionResponse.self, from: data)
        return predictionResponse
      } catch {
        print("JSON Decoding Error: \(error)")
        throw AlzheimerDetectionError.invalidResponse
      }

    } catch {
      if error is AlzheimerDetectionError {
        throw error
      } else {
        throw AlzheimerDetectionError.networkError(error.localizedDescription)
      }
    }
  }
}

// MARK: - Usage Examples
func exampleUsage() async {
  let service = AlzheimerDetectionService()

  // Example 1: Single utterance
  do {
    let response = try await service.analyzeUtteranceForAlzheimers(
      utterance: "Hello, how are you today?",
      duration: 2.5
    )
    print("Probability: \(response.probability)")
    print(
      "Prediction: \(response.prediction == 1 ? "Alzheimer's detected" : "No Alzheimer's detected")"
    )
    print("Confidence: \(response.confidence)")
  } catch {
    print("Error: \(error.localizedDescription)")
  }

  // Example 2: Multiple utterances
  let utterances = [
    TrialData(utterance: "Hello, how are you today?", duration: 2.5),
    TrialData(utterance: "I'm feeling quite well", duration: 1.8),
    TrialData(utterance: "The weather is nice outside", duration: 2.1),
  ]

  do {
    let response = try await service.analyzeMultipleUtterances(utterances)
    print("Multiple utterances analysis:")
    print("Probability: \(response.probability)")
    print(
      "Prediction: \(response.prediction == 1 ? "Alzheimer's detected" : "No Alzheimer's detected")"
    )
    print("Confidence: \(response.confidence)")
  } catch {
    print("Error: \(error.localizedDescription)")
  }
}
