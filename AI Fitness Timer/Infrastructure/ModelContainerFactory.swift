import Foundation
import SwiftData

enum ModelContainerFactory {
    static func makeCloudContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([WorkoutPlan.self, ExerciseItem.self, WorkoutSession.self, WorkoutTemplate.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: inMemory ? .none : .automatic)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeLocalContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([PlanLocalMetadata.self, SessionLocalMetadata.self, HealthProfile.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
