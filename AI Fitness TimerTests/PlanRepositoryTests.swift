import SwiftData
import XCTest
@testable import AI_Fitness_Timer

final class PlanRepositoryTests: XCTestCase {
    @MainActor
    func testCreateAndFetchPlan() throws {
        let container = try ModelContainerFactory.makeCloudContainer(inMemory: true)
        let context = ModelContext(container)
        let repo = PlanRepository(context: context)
        let template = ExerciseTemplate(id: "chair_squat", name: "椅子深蹲", duration: 30, sets: 3, restTime: 30, instructions: "做动作", safety: "注意安全", difficulty: .easy, categories: [], alternatives: [])
        let plan = WorkoutPlan(name: "测试计划", exercises: [ExerciseItem(template: template)])

        try repo.save(plan)
        XCTAssertEqual(try repo.fetchPlan(id: plan.id)?.name, "测试计划")
    }
}
