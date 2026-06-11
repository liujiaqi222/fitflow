import SwiftData
import XCTest
@testable import AI_Fitness_Timer

final class HealthProfileStoreTests: XCTestCase {
    @MainActor
    func testSnapshotUsesSingletonProfile() throws {
        let container = try ModelContainerFactory.makeLocalContainer(inMemory: true)
        let store = HealthProfileStore(context: ModelContext(container))
        let profile = try store.current()
        profile.bodyStatusDescription = "膝盖不适"
        profile.contraindications = ["wall_sit"]
        profile.dislikedExercises = ["chair_squat"]
        profile.goalPreferences = ["康复"]
        try store.save()

        let snapshot = try store.snapshot()
        XCTAssertEqual(snapshot.bodyStatus, "膝盖不适")
        XCTAssertEqual(snapshot.contraindicationIDs, ["wall_sit"])
        XCTAssertEqual(snapshot.dislikedIDs, ["chair_squat"])
        XCTAssertEqual(snapshot.goals, ["康复"])
    }
}
