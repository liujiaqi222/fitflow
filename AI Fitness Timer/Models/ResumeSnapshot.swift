import Foundation

struct ResumeSnapshot: Codable, Equatable {
    let planID: UUID
    let exerciseIndex: Int
    let currentSet: Int
    let phase: Phase
    let phaseRemainingSeconds: Int
    let completedIDs: [String]
    let skippedIDs: [String]
    let totalElapsed: Int
    let savedAt: Date

    var isExpired: Bool {
        Date().timeIntervalSince(savedAt) > 30 * 60
    }
}
