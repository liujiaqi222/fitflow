import Foundation

enum PlanSource: String, Codable { case aiGenerated, manual, template }
enum Difficulty: String, Codable { case easy, moderate }
enum Feeling: String, Codable { case easy, moderate, hard, pain }
enum Phase: String, Codable, Hashable { case idle, exercise, rest, completed }
enum VoiceMode: String, Codable, CaseIterable { case off, first, every, rest, safety }
enum AIProviderID: String, Codable, CaseIterable { case mock, claude, openai }
