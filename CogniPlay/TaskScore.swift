import Foundation

protocol TaskScore: Codable {
  func convertToMMSE() -> Int
}

struct AnyTaskScore: Codable {
  private let _decode: (Any.Type) -> Any?
  private let _convertToMMSE: () -> Int
  private let data: Data
  private let typeName: String

  init<T: TaskScore>(_ score: T) {
    self.typeName = String(describing: T.self)
    self.data = (try? JSONEncoder().encode(score)) ?? Data()
    self._convertToMMSE = { score.convertToMMSE() }

    // Store data in a local variable to avoid capturing self
    let capturedData = self.data
    self._decode = { type in
      guard type is T.Type,
        let decoded = try? JSONDecoder().decode(T.self, from: capturedData)
      else {
        return nil
      }
      return decoded
    }
  }

  func decode<T: TaskScore>(as type: T.Type) -> T? {
    return _decode(type) as? T
  }

  func convertToMMSE() -> Int {
    return _convertToMMSE()
  }

  enum CodingKeys: String, CodingKey {
    case data, typeName
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.data = try container.decode(Data.self, forKey: .data)
    self.typeName = try container.decode(String.self, forKey: .typeName)

    // Reconstruct closures based on type name
    switch typeName {
    case "SpeechScore":
      if let score = try? JSONDecoder().decode(SpeechScore.self, from: data) {
        self._convertToMMSE = { score.convertToMMSE() }
        self._decode = { type in
          guard type is SpeechScore.Type else { return nil }
          return score
        }
      } else {
        self._convertToMMSE = { 0 }
        self._decode = { _ in nil }
      }
    case "SRTTScore":
      if let score = try? JSONDecoder().decode(SRTTScore.self, from: data) {
        self._convertToMMSE = { score.convertToMMSE() }
        self._decode = { type in
          guard type is SRTTScore.Type else { return nil }
          return score
        }
      } else {
        self._convertToMMSE = { 0 }
        self._decode = { _ in nil }
      }
    case "CorsiScore":
      if let score = try? JSONDecoder().decode(GenericScore.self, from: data) {
        self._convertToMMSE = { score.convertToMMSE() }
        self._decode = { type in
          guard type is GenericScore.Type else { return nil }
          return score
        }
      } else {
        self._convertToMMSE = { 0 }
        self._decode = { _ in nil }
      }
    case "ClockScore":
      if let score = try? JSONDecoder().decode(GenericScore.self, from: data) {
        self._convertToMMSE = { score.convertToMMSE() }
        self._decode = { type in
          guard type is GenericScore.Type else { return nil }
          return score
        }
      } else {
        self._convertToMMSE = { 0 }
        self._decode = { _ in nil }
      }
    default:
      self._convertToMMSE = { 0 }
      self._decode = { _ in nil }
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(data, forKey: .data)
    try container.encode(typeName, forKey: .typeName)
  }
}

struct GenericScore: TaskScore {
  let value: Int
  let details: [String: String]?

  func convertToMMSE() -> Int {
    return value
  }
}
