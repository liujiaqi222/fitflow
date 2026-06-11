import Foundation
import SwiftData

@Model
final class PlanLocalMetadata {
    var planID: UUID = UUID()
    var userContext: String = ""

    init(planID: UUID = UUID(), userContext: String = "") {
        self.planID = planID
        self.userContext = userContext
    }
}

@Model
final class SessionLocalMetadata {
    var sessionID: UUID = UUID()
    var notes: String = ""

    init(sessionID: UUID = UUID(), notes: String = "") {
        self.sessionID = sessionID
        self.notes = notes
    }
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

    init(
        id: UUID = HealthProfile.singletonID,
        bodyStatusDescription: String = "",
        contraindications: [String] = [],
        dislikedExercises: [String] = [],
        injuryHistory: String = "",
        goalPreferences: [String] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.bodyStatusDescription = bodyStatusDescription
        self.contraindications = contraindications
        self.dislikedExercises = dislikedExercises
        self.injuryHistory = injuryHistory
        self.goalPreferences = goalPreferences
        self.updatedAt = updatedAt
    }
}
