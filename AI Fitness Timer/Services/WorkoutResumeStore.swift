import Foundation

protocol WorkoutResumeStore {
    func save(_ snapshot: ResumeSnapshot)
    func load() -> ResumeSnapshot?
    func clear()
}

final class UserDefaultsWorkoutResumeStore: WorkoutResumeStore {
    private let defaults: UserDefaults
    private let key = "workout.resume.snapshot"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ snapshot: ResumeSnapshot) {
        let data = try? JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: key)
    }

    func load() -> ResumeSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ResumeSnapshot.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
