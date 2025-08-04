import SwiftUI

// Protocol for task scores to ensure they can be encoded/decoded
protocol TaskScore: Codable {
  func convertToMMSE() -> Int
}

// Example score implementations for different task types
struct WhackAMoleScore: TaskScore {
  let score: Double

  func convertToMMSE() -> Int {
    // TODO: Implement conversion logic based on performance metrics
    // Example: return Int(accuracy * 30) // Scale accuracy to MMSE range
    return 0
  }
}

struct SimonMemoryScore: TaskScore {
  let score: Int

  func convertToMMSE() -> Int {
    // TODO: Implement conversion logic based on memory performance
    // Example: return min(30, level * 3 + Int(Double(correctSequences)/Double(totalAttempts) * 10))
    return 0
  }
}

struct SpeechScore: TaskScore {
  let probability: Double

  func convertToMMSE() -> Int {
    // TODO: Implement conversion logic based on speech metrics
    // Example: return Int((clarity + fluency) / 2.0 * 30)
    return 0
  }
}

struct TestPatternScore: TaskScore {
  let score: Int

  func convertToMMSE() -> Int {
    // TODO: Implement conversion logic based on response time and accuracy
    // Example: return completed ? Int(accuracy * 30 - min(responseTime * 2, 10)) : 0
    return 0
  }
}

struct GenericScore: TaskScore {
  let value: String
  let details: [String: String]?

  func convertToMMSE() -> Int {
    // TODO: Implement conversion logic based on generic value and details
    // This could parse numeric values from the string or details dictionary
    // Example: if let numericValue = Int(value) { return min(30, numericValue) }
    return 0
  }
}

// Type-erased wrapper for storing any TaskScore
struct AnyTaskScore: Codable {
  private let _data: Data
  private let _typeName: String

  init<T: TaskScore>(_ score: T) {
    self._typeName = String(describing: T.self)
    self._data = (try? JSONEncoder().encode(score)) ?? Data()
  }

  func decode<T: TaskScore>(as type: T.Type) -> T? {
    return try? JSONDecoder().decode(type, from: _data)
  }
}

struct SessionTask {
  let id: String
  let name: String
  let duration: String
  var isCompleted: Bool = false
  var isLocked: Bool = true
  var isOptional: Bool = false
  var score: AnyTaskScore? = nil

  // Convenience method to set score with type safety
  mutating func setScore<T: TaskScore>(_ score: T) {
    self.score = AnyTaskScore(score)
  }

  // Convenience method to get score with type safety
  func getScore<T: TaskScore>(as type: T.Type) -> T? {
    return score?.decode(as: type)
  }
}

class SessionManager: ObservableObject {
  static let shared = SessionManager()

  @Published var currentSession: Session?
  @Published var sessions: [Session] = []

  func createNewSession() {
    let newSession = Session(
      id: UUID().uuidString,
      date: Date(),
      tasks: createDefaultTasks()
    )
    currentSession = newSession
    sessions.append(newSession)
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

  // New method to complete task with score
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

  // Method to update score without completing task (useful for in-progress scoring)
  func updateTaskScore<T: TaskScore>(_ taskId: String, score: T) {
    guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSession?.id }),
      let taskIndex = sessions[sessionIndex].tasks.firstIndex(where: { $0.id == taskId })
    else { return }

    sessions[sessionIndex].tasks[taskIndex].setScore(score)
    currentSession = sessions[sessionIndex]
    saveSessions()
  }

  // Method to get MMSE score for a specific task
  func getTaskMMSEScore(_ taskId: String) -> Int? {
    guard let session = currentSession,
      let task = session.tasks.first(where: { $0.id == taskId }),
      let score = task.score
    else { return nil }

    // The AnyTaskScore wrapper needs to provide access to convertToMMSE
    // For now, we'll need to try each known score type
    if let whackScore = task.getScore(as: WhackAMoleScore.self) {
      return whackScore.convertToMMSE()
    } else if let simonScore = task.getScore(as: SimonMemoryScore.self) {
      return simonScore.convertToMMSE()
    } else if let speechScore = task.getScore(as: SpeechScore.self) {
      return speechScore.convertToMMSE()
    } else if let testScore = task.getScore(as: TestPatternScore.self) {
      return testScore.convertToMMSE()
    } else if let genericScore = task.getScore(as: GenericScore.self) {
      return genericScore.convertToMMSE()
    }

    return nil
  }

  // Method to get task score
  func getTaskScore<T: TaskScore>(_ taskId: String, as type: T.Type) -> T? {
    guard let session = currentSession,
      let task = session.tasks.first(where: { $0.id == taskId })
    else { return nil }

    return task.getScore(as: type)
  }

  // Method to get combined MMSE score for all completed tasks in current session
  func getCombinedMMSEScore() -> Int {
    guard let session = currentSession else { return 0 }

    var totalScore = 0
    let completedTasks = session.tasks.filter { $0.isCompleted && $0.score != nil }

    for task in completedTasks {
      if let mmseScore = getTaskMMSEScore(task.id) {
        totalScore += mmseScore
      }
    }

    // You might want to apply different weighting or normalization here
    return min(30, totalScore)  // Cap at 30 to match MMSE scale
  }

  private func updateTaskLocks() {
    guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSession?.id }) else {
      return
    }

    // Unlock first task if locked
    if !sessions[sessionIndex].tasks.isEmpty {
      sessions[sessionIndex].tasks[0].isLocked = false
    }

    // Unlock optional tasks
    for i in 1..<sessions[sessionIndex].tasks.count {
      if sessions[sessionIndex].tasks[i].isOptional {
        sessions[sessionIndex].tasks[i].isLocked = false
      }
    }

    // Unlock all tasks other than test pattern if setup is completed
    if sessions[sessionIndex].tasks.first(where: { $0.id == "setup" })?.isCompleted == true {
      for i in 1..<sessions[sessionIndex].tasks.count {
        if sessions[sessionIndex].tasks[i].id != "test" {
          sessions[sessionIndex].tasks[i].isLocked = false
        }
      }
    }

    if sessions[sessionIndex].tasks.filter({ !$0.isOptional && $0.id != "test" }).allSatisfy({
      $0.isCompleted
    }) {
      if let testPatternIndex = sessions[sessionIndex].tasks.firstIndex(where: { $0.id == "test" })
      {
        sessions[sessionIndex].tasks[testPatternIndex].isLocked = false
      }
    }

    currentSession = sessions[sessionIndex]
  }

  private func createDefaultTasks() -> [SessionTask] {
    return [
      SessionTask(
        id: "setup", name: "Setup Pattern", duration: "(0:30)", isLocked: false),
      SessionTask(id: "whack", name: "Whack-a-Mole", duration: "(0:30)"),
      SessionTask(id: "simon", name: "Simon Memory", duration: "(1:30)"),
      SessionTask(id: "speech", name: "Speech", duration: "(1:00)"),
      SessionTask(id: "test", name: "Test Pattern", duration: "(0:30)"),
      SessionTask(
        id: "heartbeat", name: "Link Watch Heartbeat Data", duration: "",
        isOptional: true),
      SessionTask(
        id: "previous", name: "Link Previous Data", duration: "",
        isOptional: true),
    ]
  }

  private func saveSessions() {
    // Save current session
    if let currentSession = currentSession,
      let encoded = try? JSONEncoder().encode(currentSession)
    {
      UserDefaults.standard.set(encoded, forKey: "currentSession")
    }

    // Save all sessions
    if let encoded = try? JSONEncoder().encode(sessions) {
      UserDefaults.standard.set(encoded, forKey: "sessions")
    }
  }

  @discardableResult
  func loadSessions() -> Bool {
    var didLoadData = false
    var isDifferentFromDefault = false

    // Load all sessions
    if let data = UserDefaults.standard.data(forKey: "sessions"),
      let loadedSessions = try? JSONDecoder().decode([Session].self, from: data),
      !loadedSessions.isEmpty
    {
      sessions = loadedSessions
      didLoadData = true
    }

    // Load current session
    if let data = UserDefaults.standard.data(forKey: "currentSession"),
      let session = try? JSONDecoder().decode(Session.self, from: data)
    {
      currentSession = session
      didLoadData = true

      // Ensure current session is in sessions array
      if !sessions.contains(where: { $0.id == session.id }) {
        sessions.append(session)
      }

      // Check if current session differs from default session
      let defaultTasks = createDefaultTasks()
      if session.tasks != defaultTasks {
        isDifferentFromDefault = true
      }
    }

    return didLoadData && isDifferentFromDefault
  }

  // Helper method to reset/clear all data (useful for testing)
  func clearAllData() {
    currentSession = nil
    sessions.removeAll()
    UserDefaults.standard.removeObject(forKey: "currentSession")
    UserDefaults.standard.removeObject(forKey: "sessions")
  }
}

struct Session: Codable, Identifiable {
  let id: String
  let date: Date
  var tasks: [SessionTask]

  var sessionTitle: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yy"
    return "Session \(formatter.string(from: date))"
  }

  var isCompleted: Bool {
    return tasks.filter { !$0.isOptional }.allSatisfy { $0.isCompleted }
  }
}

extension SessionTask: Codable {}

extension SessionTask: Equatable {
  static func == (lhs: SessionTask, rhs: SessionTask) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.duration == rhs.duration
      && lhs.isCompleted == rhs.isCompleted && lhs.isLocked == rhs.isLocked
      && lhs.isOptional == rhs.isOptional
    // Note: We're not comparing scores in equality check to maintain existing behavior
  }
}
