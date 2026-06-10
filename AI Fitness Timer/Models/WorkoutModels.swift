import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseItem]? = []
    var createdAt: Date = Date()
    var source: PlanSource = PlanSource.aiGenerated
    var localMetadataID: UUID?
    var restTimeAfterLastSet: Int = 20

    init(id: UUID = UUID(), name: String = "", exercises: [ExerciseItem] = [], source: PlanSource = .aiGenerated, restTimeAfterLastSet: Int = 20) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.source = source
        self.restTimeAfterLastSet = restTimeAfterLastSet
    }
}

@Model
final class ExerciseItem {
    var id: UUID = UUID()
    var templateId: String = ""
    var name: String = ""
    var duration: Int = 30
    var sets: Int = 3
    var restTime: Int = 30
    var instructions: String = ""
    var safety: String = ""
    var difficulty: Difficulty = Difficulty.easy
    var order: Int = 0

    init(template: ExerciseTemplate, sets: Int? = nil, duration: Int? = nil, restTime: Int? = nil, order: Int = 0) {
        self.templateId = template.id
        self.name = template.name
        self.duration = duration ?? template.duration
        self.sets = sets ?? template.sets
        self.restTime = restTime ?? template.restTime
        self.instructions = template.instructions
        self.safety = template.safety
        self.difficulty = template.difficulty
        self.order = order
    }

    init() {}
}

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var plan: WorkoutPlan?
    var completedExerciseIds: [String] = []
    var skippedExerciseIds: [String] = []
    var totalSeconds: Int = 0
    var feeling: Feeling = Feeling.easy
    var painScore: Int = 0
    var localMetadataID: UUID?
}

@Model
final class WorkoutTemplate {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseItem]? = []
    var createdAt: Date = Date()
}
