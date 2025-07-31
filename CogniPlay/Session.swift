import SwiftUI

struct SessionTask {
  let id: String
  let name: String
  let duration: String
  var isCompleted: Bool = false
  var isLocked: Bool = true
  var isOptional: Bool = false
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

  private func updateTaskLocks() {
    guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSession?.id }) else {
      return
    }

    // Unlock first task if locked
    if !sessions[sessionIndex].tasks.isEmpty {
      sessions[sessionIndex].tasks[0].isLocked = false
    }

    // Unlock all tasks other than test pattern if setup is completed
    if sessions[sessionIndex].tasks.first(where: { $0.id == "setup" })?.isCompleted == true {
      for i in 1..<sessions[sessionIndex].tasks.count {
        if sessions[sessionIndex].tasks[i].id != "test" {
          sessions[sessionIndex].tasks[i].isLocked = false
        }
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
      SessionTask(id: "speechSpeed", name: "Speech (Speed)", duration: "(1:00)"),
      SessionTask(id: "speechImage", name: "Speech (Image)", duration: "(1:00)"),
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
  }
}
