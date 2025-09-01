import AVFoundation
import Speech
import SwiftUI

struct SpeechView: View {
  @Binding var currentView: ContentView.AppView
  @State private var speechScore: Double = 0.0

  @StateObject private var audioRecorder = AudioRecorder()
  @StateObject private var speechRecognizer = SpeechRecognizer()
  @StateObject private var alzheimerAPI = AlzheimerAPI()
  @ObservedObject private var sessionManager = SessionManager.shared

  // Recording state
  @State private var recordingTime = "00:00"
  @State private var timer: Timer?
  @State private var recordingDuration: TimeInterval = 0

  // Results state
  @State private var transcription = ""
  @State private var utterances: [Utterance] = []
  @State private var predictionResult: APIResponse?

  // UI state
  @State private var isProcessing = false
  @State private var errorMessage = ""
  @State private var showError = false
  @State private var apiKeyValid = true  // Assuming API is available

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // MARK: - Header
      headerSection

      // MARK: - Conditional Content: Cookie Image OR Results
      if hasResults {
        // Show results when available
        resultsScrollView
          .frame(maxHeight: .infinity)  // Take up more space
      } else {
        // Show cookie image when no results
        Image("Cookie")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      Spacer()

      // MARK: - Recording Controls
      recordingControlsSection

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

  // MARK: - Computed Properties
  private var hasResults: Bool {
    // Removed showError from here - only show results if we have actual content
    !transcription.isEmpty || predictionResult != nil
  }

  // Update your resultsScrollView to not show errors:
  private var resultsScrollView: some View {
    VStack(spacing: 20) {
      if let result = predictionResult {
        predictionResultView(result: result)
      }
    }
    .padding(.top, 20)
  }

  // MARK: - View Components
  private var headerSection: some View {
    VStack(spacing: 15) {
      Text("Speech Analysis")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Audio Transcription & Analysis")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.primary)
    }
    .padding(.bottom, 30)
  }

  private func predictionResultView(result: APIResponse) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Analysis Results:")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.green)

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Prediction:")
            .fontWeight(.medium)
          Spacer()
          Text(result.prediction == 1 ? "Dementia" : "Normal")
            .fontWeight(.semibold)
            .foregroundColor(result.prediction == 1 ? .red : .green)
        }

        // // Display additional info if available
        // if let additionalInfo = result.additionalInfo {
        //   ForEach(Array(additionalInfo.keys.sorted()), id: \.self) { key in
        //     HStack {
        //       Text("\(key.capitalized):")
        //         .fontWeight(.medium)
        //       Spacer()
        //       Text("\(additionalInfo[key] ?? "N/A")")
        //         .fontWeight(.semibold)
        //     }
        //   }
        // }
      }
      .padding()
      .background(Color.green.opacity(0.1))
      .cornerRadius(8)
    }
    .padding(.horizontal, 20)
  }

  private var recordingControlsSection: some View {
    VStack(spacing: 20) {
      // Microphone button
      microphoneButton

      // Timer with minimum duration indication
      timerView

      // Processing indicator
      if isProcessing {
        processingIndicator
      }

      // API Status indicator
      apiStatusIndicator

      // Submit button
      submitButton

      // Done button (appears after analysis)
      if predictionResult != nil {
        doneButton
      }
    }
  }

  private var microphoneButton: some View {
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
  }

  private var timerView: some View {
    VStack(spacing: 5) {
      Text(recordingTime)
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(audioRecorder.isRecording ? .red : .primary)

      // Show minimum duration indicator
      if audioRecorder.isRecording {
        let remainingTime = max(0, 30 - Int(recordingDuration))
        if remainingTime > 0 {
          Text("Minimum: \(remainingTime)s remaining")
            .font(.caption)
            .foregroundColor(.orange)
        } else {
          Text("Minimum duration reached")
            .font(.caption)
            .foregroundColor(.green)
        }
      }
    }
  }

  private var processingIndicator: some View {
    HStack {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle())
      Text("Processing audio...")
        .font(.body)
        .foregroundColor(.secondary)
    }
  }

  private var apiStatusIndicator: some View {
    HStack {
      Circle()
        .fill(apiKeyValid ? Color.green : Color.red)
        .frame(width: 8, height: 8)
      Text(apiKeyValid ? "API Connected" : "API Disconnected")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var submitButton: some View {
    Button(action: {
      if audioRecorder.hasRecording && apiKeyValid {
        // Check if recording meets minimum duration
        if recordingDuration < 30 && audioRecorder.hasRecording {
          showError = true
          errorMessage =
            "Recording must be at least 30 seconds long. Current duration: \(Int(recordingDuration)) seconds"
          return
        }
        processAudio()
      } else if !apiKeyValid {
        sessionManager.completeTask("speech", withScore: SpeechScore(probability: 0.0))
        currentView = .sessionChecklist
      }
    }) {
      VStack(spacing: 4) {
        Text(isProcessing ? "Processing..." : buttonTitle)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.white)

        // Show error message in button if there's an error
        if showError && !errorMessage.isEmpty {
          Text(errorMessage)
            .font(.caption)
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 50)
      .background(buttonBackgroundColor)
      .cornerRadius(10)
      .animation(.easeInOut(duration: 0.3), value: apiKeyValid)
      .animation(.easeInOut(duration: 0.3), value: showError)
    }
    .padding(.horizontal, 30)
    .disabled(
      (!audioRecorder.hasRecording && apiKeyValid) || isProcessing
        || (audioRecorder.hasRecording && recordingDuration < 30 && apiKeyValid))
  }

  private var doneButton: some View {
    Button(action: {
      // Complete the task with the current speech score
      sessionManager.completeTask("speech", withScore: SpeechScore(probability: speechScore))
      currentView = .sessionChecklist
    }) {
      Text("Done")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.green)
        .cornerRadius(10)
    }
    .padding(.horizontal, 30)
    .padding(.top, 10)
  }

  // MARK: - Computed Properties
  private var buttonTitle: String {
    if !apiKeyValid {
      return "Skip Task"
    }
    if audioRecorder.hasRecording && recordingDuration < 30 {
      return "Recording too short (\(Int(recordingDuration))s/30s)"
    }
    return "Analyze Audio"
  }

  private var buttonBackgroundColor: Color {
    if showError {
      return Color.red  // Red background when there's an error
    }
    if !apiKeyValid {
      return Color.green
    }
    if audioRecorder.hasRecording && recordingDuration < 30 {
      return Color.orange.opacity(0.7)
    }
    return audioRecorder.hasRecording && !isProcessing ? Color.blue : Color.gray.opacity(0.7)
  }
}

// MARK: - Setup and Cleanup Functions
extension SpeechView {
  private func requestPermissionsAndSetup() {
    audioRecorder.requestPermission()
    requestSpeechPermission()
  }

  private func requestSpeechPermission() {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      if !granted {
        DispatchQueue.main.async {
          self.errorMessage = "Microphone permission denied"
          self.showError = true
        }
      }
    }

    SFSpeechRecognizer.requestAuthorization { status in
      if status != .authorized {
        DispatchQueue.main.async {
          self.errorMessage = "Speech recognition permission denied"
          self.showError = true
        }
      }
    }
  }

  private func cleanup() {
    stopRecording()
    timer?.invalidate()
    timer = nil
  }
}

// MARK: - Recording Functions
extension SpeechView {
  private func startRecording() {
    // Reset states - Clear error when starting new recording
    recordingDuration = 0
    updateTimer()
    transcription = ""
    utterances = []
    predictionResult = nil
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

    // Check minimum duration after stopping
    if recordingDuration < 30 {
      showError = true
      errorMessage = ""
    }
  }

  private func updateTimer() {
    let minutes = Int(recordingDuration) / 60
    let seconds = Int(recordingDuration) % 60
    recordingTime = String(format: "%02d:%02d", minutes, seconds)
  }
}

// MARK: - Audio Processing Functions
extension SpeechView {
  private func processAudio() {
    guard let audioURL = audioRecorder.audioFileURL else {
      showError = true
      errorMessage = "No audio file found"
      return
    }

    // Double-check minimum duration before processing
    guard recordingDuration >= 30 else {
      showError = true
      errorMessage = "Recording must be at least 30 seconds long"
      return
    }

    isProcessing = true
    showError = false  // Clear any previous errors when starting processing
    errorMessage = ""

    // First transcribe the audio
    speechRecognizer.transcribe(audioURL: audioURL) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let transcriptionResult):
          self.transcription = transcriptionResult.text
          self.utterances = transcriptionResult.utterances
          self.sendToAPI()
        case .failure(let error):
          self.isProcessing = false
          self.showError = true
          self.errorMessage = "Transcription failed: \(error.localizedDescription)"
          self.speechScore = 0.0
          self.audioRecorder.deleteCurrentRecording()
        }
      }
    }
  }

  private func sendToAPI() {
    guard !utterances.isEmpty else {
      isProcessing = false
      showError = true
      errorMessage = "No utterances to analyze"
      speechScore = 0.0
      audioRecorder.deleteCurrentRecording()
      return
    }

    // Prepare data for API - each sentence with its own duration
    let sentenceData = utterances.map { utterance in
      [
        "sentence": utterance.text,
        "duration": utterance.duration,
      ]
    }

    // Call API with individual sentences
    alzheimerAPI.predict(sentences: sentenceData) { result in
      DispatchQueue.main.async {
        self.isProcessing = false

        switch result {
        case .success(let response):
          self.predictionResult = response
          // Clear any errors on successful API response
          self.showError = false
          self.errorMessage = ""
          // Extract probability/score from response if available
          if let probability = response.probability {
            self.speechScore = probability
          } else {
            // Default scoring based on prediction
            self.speechScore = response.prediction == 1 ? 0.8 : 0.2
          }
        case .failure(let error):
          self.showError = true
          self.errorMessage = "API Error: \(error.localizedDescription)"
          self.speechScore = 0.0
        }

        // Clean up the audio file after processing
        self.audioRecorder.deleteCurrentRecording()
      }
    }
  }
}

// MARK: - Data Models
struct Utterance {
  let text: String
  let duration: Double
}

struct TranscriptionResult {
  let text: String
  let utterances: [Utterance]
}

struct APIResponse {
  let prediction: Int?
  let probability: Double?
  let additionalInfo: [String: Any]?

  init(from dictionary: [String: Any]) {
    self.prediction = dictionary["prediction"] as? Int
    self.probability = dictionary["probability"] as? Double

    // Store any additional fields
    var info: [String: Any] = [:]
    for (key, value) in dictionary {
      if key != "prediction" && key != "probability" {
        info[key] = value
      }
    }
    self.additionalInfo = info.isEmpty ? nil : info
  }
}

// MARK: - Audio Recorder
class AudioRecorder: NSObject, ObservableObject {
  @Published var isRecording = false
  @Published var hasRecording = false

  private var audioRecorder: AVAudioRecorder?
  var audioFileURL: URL?

  func requestPermission() {
    AVAudioSession.sharedInstance().requestRecordPermission { _ in }
  }

  func startRecording() {
    let audioSession = AVAudioSession.sharedInstance()

    do {
      try audioSession.setCategory(.playAndRecord, mode: .default)
      try audioSession.setActive(true)

      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
      audioFileURL = audioFilename

      let settings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
      ]

      audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      audioRecorder?.record()

      DispatchQueue.main.async {
        self.isRecording = true
      }
    } catch {
      print("Failed to start recording: \(error)")
    }
  }

  func stopRecording() {
    audioRecorder?.stop()
    audioRecorder = nil

    DispatchQueue.main.async {
      self.isRecording = false
      self.hasRecording = true
    }
  }

  func deleteCurrentRecording() {
    if let url = audioFileURL {
      try? FileManager.default.removeItem(at: url)
    }
    audioFileURL = nil
    hasRecording = false
  }
}

// MARK: - Speech Recognizer
class SpeechRecognizer: NSObject, ObservableObject {
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

  func transcribe(audioURL: URL, completion: @escaping (Result<TranscriptionResult, Error>) -> Void)
  {
    guard let recognizer = speechRecognizer, recognizer.isAvailable else {
      completion(
        .failure(
          NSError(
            domain: "SpeechRecognizer", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])))
      return
    }

    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    request.shouldReportPartialResults = false

    recognizer.recognitionTask(with: request) { result, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let result = result, result.isFinal else {
        return
      }

      let segments = result.bestTranscription.segments
      let utterances = self.segmentIntoSentences(segments: segments)

      let transcriptionResult = TranscriptionResult(
        text: result.bestTranscription.formattedString,
        utterances: utterances
      )

      completion(.success(transcriptionResult))
    }
  }

  private func segmentIntoSentences(segments: [SFTranscriptionSegment]) -> [Utterance] {
    var utterances: [Utterance] = []
    var currentSentence = ""
    var sentenceStartTime: TimeInterval = 0
    var wordCount = 0

    for (index, segment) in segments.enumerated() {
      if index == 0 || currentSentence.isEmpty {
        sentenceStartTime = segment.timestamp
      }

      currentSentence += segment.substring
      wordCount += 1

      let trimmedSubstring = segment.substring.trimmingCharacters(in: .whitespaces)
      let isEndOfSentence =
        trimmedSubstring.hasSuffix(".") || trimmedSubstring.hasSuffix("!")
        || trimmedSubstring.hasSuffix("?")

      let isLastSegment = index == segments.count - 1
      let hasMinimumWords = wordCount >= 3  // Minimum words per sentence

      // End sentence if: punctuation found, last segment, or sentence is getting too long
      if (isEndOfSentence && hasMinimumWords) || isLastSegment || wordCount >= 15 {
        let sentenceEndTime = segment.timestamp + segment.duration
        let duration = sentenceEndTime - sentenceStartTime

        // Only add sentences with meaningful duration and content
        let cleanSentence = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanSentence.isEmpty && duration > 0.5 {
          utterances.append(Utterance(text: cleanSentence, duration: duration))
        }

        // Reset for next sentence
        currentSentence = ""
        wordCount = 0
      } else {
        // Add space between words if not at punctuation
        if !trimmedSubstring.hasSuffix(",") && !trimmedSubstring.hasSuffix(".")
          && !trimmedSubstring.hasSuffix("!") && !trimmedSubstring.hasSuffix("?")
        {
          currentSentence += " "
        } else {
          currentSentence += " "
        }
      }
    }

    // Handle any remaining sentence
    if !currentSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !segments.isEmpty
    {
      let duration = segments.last!.timestamp + segments.last!.duration - sentenceStartTime
      if duration > 0.5 {
        utterances.append(
          Utterance(
            text: currentSentence.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: duration
          ))
      }
    }

    // Fallback: if no sentences were created, create one from the full transcription
    if utterances.isEmpty && !segments.isEmpty {
      let totalDuration =
        segments.last!.timestamp + segments.last!.duration - segments.first!.timestamp
      let fullText = segments.map { $0.substring }.joined(separator: " ")
      utterances.append(Utterance(text: fullText, duration: totalDuration))
    }

    return utterances
  }
}

// MARK: - API Client
class AlzheimerAPI: ObservableObject {
  private let apiURL = "https://cogniplayapp-alzheimer-detection-api.hf.space/predict"

  func predict(
    sentences: [[String: Any]],
    completion: @escaping (Result<APIResponse, Error>) -> Void
  ) {
    guard let url = URL(string: apiURL) else {
      completion(
        .failure(
          NSError(domain: "API", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Updated payload structure for individual sentences
    let payload = ["sentences": sentences]

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    } catch {
      completion(.failure(error))
      return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(
          .failure(
            NSError(
              domain: "API", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }

      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          let apiResponse = APIResponse(from: json)
          completion(.success(apiResponse))
        } else {
          completion(
            .failure(
              NSError(
                domain: "API", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
        }
      } catch {
        completion(.failure(error))
      }
    }.resume()
  }
}
