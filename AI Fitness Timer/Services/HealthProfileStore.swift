import Foundation
import SwiftData

@MainActor
final class HealthProfileStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func current() throws -> HealthProfile {
        let id = HealthProfile.singletonID
        let descriptor = FetchDescriptor<HealthProfile>(predicate: #Predicate { $0.id == id })
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let profile = HealthProfile()
        context.insert(profile)
        try context.save()
        return profile
    }

    func snapshot() throws -> HealthProfileSnapshot {
        let profile = try current()
        return HealthProfileSnapshot(
            bodyStatus: profile.bodyStatusDescription,
            contraindicationIDs: profile.contraindications,
            dislikedIDs: profile.dislikedExercises,
            injuryHistory: profile.injuryHistory,
            goals: profile.goalPreferences
        )
    }

    func addContraindication(_ templateID: String) throws {
        let profile = try current()
        if !profile.contraindications.contains(templateID) {
            profile.contraindications.append(templateID)
            profile.updatedAt = Date()
            try context.save()
        }
    }

    func addDislikedExercise(_ templateID: String) throws {
        let profile = try current()
        if !profile.dislikedExercises.contains(templateID) {
            profile.dislikedExercises.append(templateID)
            profile.updatedAt = Date()
            try context.save()
        }
    }

    func clear() throws {
        let profile = try current()
        profile.bodyStatusDescription = ""
        profile.contraindications = []
        profile.dislikedExercises = []
        profile.injuryHistory = ""
        profile.goalPreferences = []
        profile.updatedAt = Date()
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
