import Foundation
import SwiftData

@Model
final class PlanLocalMetadata {
    var planID: UUID = UUID()
    var userContext: String = ""
}

@Model
final class SessionLocalMetadata {
    var sessionID: UUID = UUID()
    var notes: String = ""
}

@Model
final class HealthProfile {
    var id: UUID = HealthProfile.singletonID
    var bodyStatusDescription: String = ""
    var contraindications: [String] = []
    var dislikedExercises: [String] = []
    var injuryHistory: String = ""
    var goalPreferences: [String] = []
    var updatedAt: Date = Date()

    static let singletonID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
}
