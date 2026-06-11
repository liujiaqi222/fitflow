import Foundation
import SwiftData

@MainActor
final class PlanRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ plan: WorkoutPlan) throws {
        context.insert(plan)
        try context.save()
    }

    func fetchPlan(id: UUID) throws -> WorkoutPlan? {
        let descriptor = FetchDescriptor<WorkoutPlan>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    func recentPlans(limit: Int = 20) throws -> [WorkoutPlan] {
        var descriptor = FetchDescriptor<WorkoutPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }
}
