import Foundation

struct ExerciseTemplate: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let duration: Int
    let sets: Int
    let restTime: Int
    let instructions: String
    let safety: String
    let difficulty: Difficulty
    let categories: [String]
    let alternatives: [String]
}
