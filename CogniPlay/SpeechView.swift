import SwiftUI

struct SpeechView: View {
  @Binding var currentView: ContentView.AppView
  @Binding var speechScore: Double
  @StateObject private var audioRecorder = AudioRecorder()
  @StateObject private var alzheimerService = AlzheimerDetectionService()
  @ObservedObject private var sessionManager = SessionManager.shared

  // Recording state
  @State private var recordingTime = "00:00"
  @State private var timer: Timer?
  @State private var recordingDuration: TimeInterval = 0

  // Results state
  @State private var transcription = ""
  @State private var predictionResult: AlzheimerPredictionResponse?

  // UI state
  @State private var isProcessing = false
  @State private var errorMessage = ""
  @State private var showError = false
  @State private var apiKeyValid = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // MARK: - Header
      headerSection

      // MARK: - Results Display
      resultsScrollView

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

  // MARK: - View Components
  private var headerSection: some View {
    VStack(spacing: 5) {
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

  private var imageSection: some View {
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
          Text("(Audio Transcription & Analysis)")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      )
      .padding(.bottom, 20)
  }

  private var resultsScrollView: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Error display
        if showError {
          errorDisplayView
        }

        // Transcription display
        if !transcription.isEmpty {
          transcriptionView
        }

        // Prediction results display
        if let result = predictionResult {
          predictionResultView(result: result)
        }
      }
    }
    .frame(maxHeight: 300)
  }

  private var errorDisplayView: some View {
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
  }

  private var transcriptionView: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text("Transcription:")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.blue)

      Text(transcription)
        .font(.body)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    .padding(.horizontal, 20)
  }

  private func predictionResultView(result: AlzheimerPredictionResponse) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Analysis Results:")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.green)

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Probability:")
            .fontWeight(.medium)
          Spacer()
          Text("\(String(format: "%.1f", result.probability * 100))%")
            .fontWeight(.semibold)
        }

        HStack {
          Text("Prediction:")
            .fontWeight(.medium)
          Spacer()
          Text(result.prediction == 1 ? "Positive" : "Negative")
            .fontWeight(.semibold)
            .foregroundColor(result.prediction == 1 ? .red : .green)
        }

        HStack {
          Text("Confidence:")
            .fontWeight(.medium)
          Spacer()
          Text(result.confidence)
            .fontWeight(.semibold)
        }

        HStack {
          Text("Speech Score:")
            .fontWeight(.medium)
          Spacer()
          Text(String(format: "%.2f", speechScore))
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
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

      // Timer
      timerView

      // Processing indicator
      if isProcessing {
        processingIndicator
      }

      // API Status indicator
      apiStatusIndicator

      // Submit button
      submitButton

      // Test API button
      testAPIButton
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
    Text(recordingTime)
      .font(.title2)
      .fontWeight(.medium)
      .foregroundColor(audioRecorder.isRecording ? .red : .primary)
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
        processAudio()
      } else if !apiKeyValid {
        sessionManager.completeTask("speech", withScore: SpeechScore(probability: 0.0))
        currentView = .sessionChecklist
      }
    }) {
      Text(isProcessing ? "Processing..." : buttonTitle)
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(buttonBackgroundColor)
        .cornerRadius(10)
        .animation(.easeInOut(duration: 0.3), value: apiKeyValid)
    }
    .padding(.horizontal, 30)
    .disabled((!audioRecorder.hasRecording && apiKeyValid) || isProcessing)
  }

  private var testAPIButton: some View {
    Button(action: {
      testAPIConnection()
    }) {
      Text("Test API Connection")
        .font(.body)
        .foregroundColor(.blue)
    }
    .disabled(isProcessing)
  }

  // MARK: - Computed Properties
  private var buttonTitle: String {
    if !apiKeyValid {
      return "Skip Task"
    }
    return "Analyze Audio"
  }

  private var buttonBackgroundColor: Color {
    if !apiKeyValid {
      return Color.green
    }
    return audioRecorder.hasRecording && !isProcessing ? Color.blue : Color.gray.opacity(0.7)
  }
}

// MARK: - Setup and Cleanup Functions
extension SpeechView {
  private func requestPermissionsAndSetup() {
    audioRecorder.requestPermission()
    testAPIConnection()
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
    // Reset states
    recordingDuration = 0
    updateTimer()
    transcription = ""
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
  }

  private func updateTimer() {
    let minutes = Int(recordingDuration) / 60
    let seconds = Int(recordingDuration) % 60
    recordingTime = String(format: "%02d:%02d", minutes, seconds)
  }
}

// MARK: - API Functions
extension SpeechView {
  private func testAPIConnection() {
    Task {
      do {
        let isValid = try await alzheimerService.validateAPIConnection()
        await MainActor.run {
          self.apiKeyValid = isValid
          if !isValid {
            self.showError = true
            self.errorMessage = "API connection failed. Please check your Cloudflare Worker URL."
          }
        }
      } catch {
        await MainActor.run {
          self.apiKeyValid = false
          self.showError = true
          self.errorMessage = "Failed to connect to API: \(error.localizedDescription)"
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
    if let audioInfo = audioRecorder.getAudioFileInfo() {
      print(audioInfo)
    }

    isProcessing = true
    showError = false
    errorMessage = ""

    // Use the full analysis instead of transcription only
    processFullAnalysis(audioURL: audioURL)
  }

  private func processFullAnalysis(audioURL: URL) {
    Task {
      do {
        // Use the analyzeAudioForAlzheimers method which does both transcription and analysis
        let result = try await alzheimerService.analyzeAudioForAlzheimers(
          audioURL: audioURL,
          recordingDuration: recordingDuration
        )

        // Also get the transcription separately for display
        let transcriptionText = try await alzheimerService.transcribeAudio(audioURL: audioURL)

        await MainActor.run {
          print("ANALYSIS RESULT: \(result)")
          print("TRANSCRIPTION: \(transcriptionText)")

          // Set the speechScore to the probability from the API response
          self.speechScore = result.probability

          // Update UI with results
          self.transcription = transcriptionText
          self.predictionResult = result
          self.isProcessing = false
          self.showError = false

          // Clean up the audio file after processing
          self.audioRecorder.deleteCurrentRecording()
        }
      } catch {
        await MainActor.run {
          print("ANALYSIS ERROR: \(error.localizedDescription)")
          self.isProcessing = false
          self.showError = true
          self.errorMessage = "Analysis failed: \(error.localizedDescription)"

          // Set speechScore to 0 on error
          self.speechScore = 0.0

          // Clean up the audio file even on error
          self.audioRecorder.deleteCurrentRecording()
        }
      }
    }
  }

  private func processTranscriptionOnly(audioURL: URL) {
    Task {
      do {
        let transcriptionText = try await alzheimerService.transcribeAudio(audioURL: audioURL)

        await MainActor.run {
          print("TRANSCRIPTION RESULT: \(transcriptionText)")
          self.transcription = transcriptionText
          self.isProcessing = false
          self.showError = false

          // Clean up the audio file after processing
          self.audioRecorder.deleteCurrentRecording()
        }
      } catch {
        await MainActor.run {
          print("TRANSCRIPTION ERROR: \(error.localizedDescription)")
          self.isProcessing = false
          self.showError = true
          self.errorMessage = "Transcription failed: \(error.localizedDescription)"

          // Clean up the audio file even on error
          self.audioRecorder.deleteCurrentRecording()
        }
      }
    }
  }
}
