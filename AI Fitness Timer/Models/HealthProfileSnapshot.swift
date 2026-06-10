import Foundation

struct HealthProfileSnapshot: Codable, Equatable {
    let bodyStatus: String
    let contraindicationIDs: [String]
    let dislikedIDs: [String]
    let injuryHistory: String
    let goals: [String]
}
