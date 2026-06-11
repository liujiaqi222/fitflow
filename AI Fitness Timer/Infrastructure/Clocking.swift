import Foundation

protocol AppClock: Sendable {
    func sleep(seconds: Int) async throws
    func now() -> ContinuousClock.Instant
}

struct SystemAppClock: AppClock {
    private let clock = ContinuousClock()

    func sleep(seconds: Int) async throws {
        try await clock.sleep(for: .seconds(seconds))
    }

    func now() -> ContinuousClock.Instant {
        clock.now
    }
}

actor MockAppClock: AppClock {
    private struct Sleeper {
        let deadline: Int
        let continuation: CheckedContinuation<Void, Error>
    }

    private var currentSecond = 0
    private var sleepers: [Sleeper] = []
    private let base = ContinuousClock().now

    func sleep(seconds: Int) async throws {
        if seconds <= 0 { return }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                sleepers.append(Sleeper(deadline: currentSecond + seconds, continuation: continuation))
                releaseReadySleepers()
            }
        } onCancel: {}
    }

    nonisolated func now() -> ContinuousClock.Instant {
        base
    }

    func advance(seconds: Int) {
        currentSecond += max(0, seconds)
        releaseReadySleepers()
    }

    private func releaseReadySleepers() {
        let ready = sleepers.filter { $0.deadline <= currentSecond }
        sleepers.removeAll { $0.deadline <= currentSecond }
        ready.forEach { $0.continuation.resume() }
    }
}
