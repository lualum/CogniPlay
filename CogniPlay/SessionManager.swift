import SwiftUI

class SessionManager: ObservableObject {
  static let shared = SessionManager()

  @Published var currentSession: Session?
  @Published var sessions: [Session] = []

  private init() {
    initializeSession()
  }

  private func initializeSession() {
    let didLoadExistingData = loadSessions()
    if !didLoadExistingData || currentSession == nil {
      createNewSession()
    }
  }

  func createNewSession() {
    let newSession = Session(
      id: UUID().uuidString,
      date: Date(),
      tasks: createDefaultTasks()
    )
    currentSession = newSession
    sessions.append(newSession)
    updateTaskLocks()
    saveSessions()
  }

  func completeTask(_ taskId: String) {
    guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSession?.id }),
      let taskIndex = sessions[sessionIndex].tasks.firstIndex(where: { $0.id == taskId })
    else { return }

    sessions[sessionIndex].tasks[taskIndex].isCompleted = true
    currentSession = sessions[sessionIndex]
    updateTaskLocks()
    saveSessions()
  }

  func completeTask<T: TaskScore>(_ taskId: String, withScore score: T) {
    guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSession?.id }),
      let taskIndex = sessions[sessionIndex].tasks.firstIndex(where: { $0.id == taskId })
    else { return }

    sessions[sessionIndex].tasks[taskIndex].isCompleted = true
    sessions[sessionIndex].tasks[taskIndex].setScore(score)
    currentSession = sessions[sessionIndex]
    updateTaskLocks()
    saveSessions()
  }

  func isTaskUnlocked(_ taskId: String) -> Bool {
    guard let session = currentSession,
      let task = session.tasks.first(where: { $0.id == taskId })
    else {
      return false
    }

    // Check if all prerequisites are completed
    return task.prerequisiteTaskIDs.allSatisfy { prereqId in
      session.tasks.first(where: { $0.id == prereqId })?.isCompleted ?? false
    }
  }

  private func updateTaskLocks() {
    guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSession?.id }) else {
      return
    }

    // Update locks based on prerequisites
    for i in 0..<sessions[sessionIndex].tasks.count {
      let task = sessions[sessionIndex].tasks[i]
      let shouldUnlock = task.prerequisiteTaskIDs.allSatisfy { prereqId in
        sessions[sessionIndex].tasks.first(where: { $0.id == prereqId })?.isCompleted ?? false
      }
      sessions[sessionIndex].tasks[i].isLocked = !shouldUnlock && !task.isOptional
    }

    currentSession = sessions[sessionIndex]
  }

  func getTaskScore<T: TaskScore>(_ taskId: String, as type: T.Type) -> T? {
    guard let session = currentSession,
      let task = session.tasks.first(where: { $0.id == taskId })
    else { return nil }

    return task.getScore(as: type)
  }

  func getCombinedMMSEScore() -> Int {
    guard let session = currentSession else { return 0 }

    var totalScore = 0
    let completedTasks = session.tasks.filter { $0.isCompleted && $0.score != nil }

    for task in completedTasks {
      if let score = task.score {
        totalScore += score.convertToMMSE()
      }
    }

    return min(30, totalScore)
  }

  private func createDefaultTasks() -> [Task] {
    return [
      Task(
        id: "speech",
        name: "Describe Image",
        duration: "(0:30)",
        tutorialSteps: [
          TutorialStep(
            title: "Record Your Description",
            description: "Tap the microphone button to start recording",
            icon: "mic.fill"
          ),
          TutorialStep(
            title: "Speak Clearly",
            description: "Describe what you see in the image for at least 30 seconds",
            icon: "waveform"
          ),
          TutorialStep(
            title: "Analysis",
            description: "Your speech will be analyzed for clarity and coherence",
            icon: "chart.bar.fill"
          ),
        ],
        prerequisiteTaskIDs: [],
        isCompleted: false,
        isLocked: false,
        isOptional: false
      ),
      Task(
        id: "srtt",
        name: "Serial Reaction Time",
        duration: "(0:30)",
        tutorialSteps: [
          TutorialStep(
            title: "Tap Quickly",
            description: "Tap the square that lights up as quickly as possible",
            icon: "hand.tap.fill"
          ),
          TutorialStep(
            title: "Speed Matters",
            description: "Respond as fast and accurately as you can",
            icon: "speedometer"
          ),
          TutorialStep(
            title: "Complete Rounds",
            description: "Complete 12 rounds to finish the task",
            icon: "arrow.clockwise"
          ),
        ],
        prerequisiteTaskIDs: [],
        isCompleted: false,
        isLocked: false,
        isOptional: false
      ),
      Task(
        id: "corsi",
        name: "Corsi Block",
        duration: "(0:30)",
        tutorialSteps: [
          TutorialStep(
            title: "Watch the Sequence",
            description: "Blocks will light up one at a time in a specific order",
            icon: "eye.fill"
          ),
          TutorialStep(
            title: "Remember the Pattern",
            description: "Memorize which blocks light up and in what order",
            icon: "brain.head.profile"
          ),
          TutorialStep(
            title: "Tap to Repeat",
            description: "After the sequence ends, tap the blocks in the same order",
            icon: "hand.tap.fill"
          ),
          TutorialStep(
            title: "Sequences Get Longer",
            description: "Start with 2 blocks and progress to longer sequences",
            icon: "arrow.up.forward"
          ),
          TutorialStep(
            title: "Two Chances Per Level",
            description: "You get 2 attempts at each sequence length before advancing",
            icon: "arrow.clockwise"
          ),
        ],
        prerequisiteTaskIDs: [],
        isCompleted: false,
        isLocked: false,
        isOptional: false
      ),
      Task(
        id: "clock",
        name: "Clock Drawing",
        duration: "(3:00)",
        tutorialSteps: [
          TutorialStep(
            title: "Draw the Circle",
            description: "Start by drawing a circle to represent the clock face",
            icon: "circle"
          ),
          TutorialStep(
            title: "Add All Numbers",
            description: "Place all 12 numbers (1-12) around the clock in their correct positions",
            icon: "textformat.123"
          ),
          TutorialStep(
            title: "Draw the Hands",
            description: "Add both the hour hand and minute hand to show the requested time",
            icon: "clock.fill"
          ),
          TutorialStep(
            title: "Check Your Time",
            description: "Make sure the hands point to the correct time: 10:10",
            icon: "checkmark.circle.fill"
          ),
          TutorialStep(
            title: "Take Your Time",
            description: "You have up to 3 minutes - focus on accuracy over speed",
            icon: "timer"
          ),
        ],
        prerequisiteTaskIDs: [],
        isCompleted: false,
        isLocked: false,
        isOptional: false
      ),
    ]
  }

  private func saveSessions() {
    if let currentSession = currentSession,
      let encoded = try? JSONEncoder().encode(currentSession)
    {
      UserDefaults.standard.set(encoded, forKey: "currentSession")
    }

    if let encoded = try? JSONEncoder().encode(sessions) {
      UserDefaults.standard.set(encoded, forKey: "sessions")
    }
  }

  @discardableResult
  func loadSessions() -> Bool {
    var didLoadData = false

    if let data = UserDefaults.standard.data(forKey: "sessions"),
      let loadedSessions = try? JSONDecoder().decode([Session].self, from: data),
      !loadedSessions.isEmpty
    {
      sessions = loadedSessions
      didLoadData = true
    }

    if let data = UserDefaults.standard.data(forKey: "currentSession"),
      let session = try? JSONDecoder().decode(Session.self, from: data)
    {
      currentSession = session
      didLoadData = true

      if !sessions.contains(where: { $0.id == session.id }) {
        sessions.append(session)
      }
    }

    return didLoadData
  }

  func clearAllData() {
    currentSession = nil
    sessions.removeAll()
    UserDefaults.standard.removeObject(forKey: "currentSession")
    UserDefaults.standard.removeObject(forKey: "sessions")
  }

  func ensureCurrentSession() {
    if currentSession == nil {
      createNewSession()
    }
  }

  func hasSessionWithProgress() -> Bool {
    loadSessions()
    guard let session = currentSession else { return false }

    let hasCompletedTasks = session.tasks.contains { $0.isCompleted }
    let hasTasksWithScores = session.tasks.contains { $0.score != nil }

    return hasCompletedTasks || hasTasksWithScores
  }
}

struct Session: Codable, Identifiable {
  let id: String
  let date: Date
  var tasks: [Task]

  var sessionTitle: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yy"
    return "Session \(formatter.string(from: date))"
  }

  var isCompleted: Bool {
    return tasks.filter { !$0.isOptional }.allSatisfy { $0.isCompleted }
  }
}
