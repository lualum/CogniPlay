import Foundation

struct Task: Identifiable, Codable {
  let id: String
  let name: String
  let duration: String
  let tutorialSteps: [TutorialStep]
  let prerequisiteTaskIDs: [String]

  var isCompleted: Bool = false
  var isLocked: Bool = true
  var isOptional: Bool = false
  var score: AnyTaskScore? = nil

  // Convenience methods
  mutating func setScore<T: TaskScore>(_ score: T) {
    self.score = AnyTaskScore(score)
  }

  func getScore<T: TaskScore>(as type: T.Type) -> T? {
    return score?.decode(as: type)
  }
}

struct TutorialStep: Identifiable, Codable {
  let id: String
  let title: String
  let description: String
  let icon: String

  init(id: String = UUID().uuidString, title: String, description: String, icon: String) {
    self.id = id
    self.title = title
    self.description = description
    self.icon = icon
  }
}

extension Task: Equatable {
  static func == (lhs: Task, rhs: Task) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
  }
}
