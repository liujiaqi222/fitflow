import Foundation
import Observation

actor WorkoutEngine: Observable {
    private(set) var phase: Phase = .idle
    private(set) var currentExerciseIndex = 0
    private(set) var currentSet = 1
    private(set) var timeRemaining = 0
    private(set) var isRunning = false
    private(set) var totalElapsed = 0
    private(set) var estimatedRemaining = 0
    private(set) var overallProgress = 0.0
    private(set) var completedExerciseIds: Set<String> = []
    private(set) var skippedExerciseIds: Set<String> = []

    private let clock: AppClock
    private var plan: WorkoutPlan?
    private var tickTask: Task<Void, Never>?
    private var totalPlannedSeconds = 0

    init(clock: AppClock = SystemAppClock()) {
        self.clock = clock
    }

    func start(plan: WorkoutPlan) {
        stopTicker()
        self.plan = plan
        currentExerciseIndex = 0
        currentSet = 1
        timeRemaining = 0
        isRunning = false
        totalElapsed = 0
        completedExerciseIds = []
        skippedExerciseIds = []
        totalPlannedSeconds = Self.totalSeconds(for: plan)
        estimatedRemaining = totalPlannedSeconds
        overallProgress = 0
        beginExercise()
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        stopTicker()
    }

    func resume() {
        guard phase == .exercise || phase == .rest else { return }
        guard !isRunning else { return }
        isRunning = true
        startTicker()
    }

    func skip() {
        guard let exercise = currentExercise else { return }
        skippedExerciseIds.insert(exercise.templateId)
        advanceToNextExercise()
    }

    func extendRest(seconds: Int = 30) {
        guard phase == .rest else { return }
        timeRemaining += seconds
        estimatedRemaining += seconds
        totalPlannedSeconds += seconds
    }

    func endWorkout() {
        completeWorkout()
    }

    private func startTicker() {
        stopTicker()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    guard let self else { return }
                    try await self.clock.sleep(seconds: 1)
                    await self.tick()
                } catch {
                    return
                }
            }
        }
    }

    private func stopTicker() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func tick() {
        guard isRunning, phase == .exercise || phase == .rest else { return }

        timeRemaining -= 1
        totalElapsed += 1
        updateProgress()

        if timeRemaining <= 0 {
            phase == .exercise ? completeExerciseSegment() : completeRestSegment()
        }
    }

    private func beginExercise() {
        guard let exercise = currentExercise else {
            completeWorkout()
            return
        }

        phase = .exercise
        timeRemaining = exercise.duration
        isRunning = true
        startTicker()
    }

    private func beginRest(seconds: Int) {
        phase = .rest
        timeRemaining = seconds
        isRunning = true
        startTicker()
    }

    private func completeExerciseSegment() {
        guard let exercise = currentExercise else {
            completeWorkout()
            return
        }

        if currentSet < exercise.sets {
            beginRest(seconds: exercise.restTime)
        } else {
            completedExerciseIds.insert(exercise.templateId)
            if isLastExercise {
                completeWorkout()
            } else {
                beginRest(seconds: plan?.restTimeAfterLastSet ?? 20)
            }
        }
    }

    private func completeRestSegment() {
        guard let exercise = currentExercise else {
            completeWorkout()
            return
        }

        if currentSet < exercise.sets {
            currentSet += 1
            beginExercise()
        } else {
            currentExerciseIndex += 1
            currentSet = 1
            beginExercise()
        }
    }

    private func advanceToNextExercise() {
        if isLastExercise {
            completeWorkout()
        } else {
            currentExerciseIndex += 1
            currentSet = 1
            beginRest(seconds: plan?.restTimeAfterLastSet ?? 20)
        }
    }

    private func completeWorkout() {
        stopTicker()
        phase = .completed
        isRunning = false
        timeRemaining = 0
        estimatedRemaining = 0
        overallProgress = 1
    }

    private func updateProgress() {
        estimatedRemaining = max(0, totalPlannedSeconds - totalElapsed)
        overallProgress = totalPlannedSeconds == 0 ? 0 : min(1, Double(totalElapsed) / Double(totalPlannedSeconds))
    }

    private var currentExercise: ExerciseItem? {
        sortedExercises[safe: currentExerciseIndex]
    }

    private var sortedExercises: [ExerciseItem] {
        (plan?.exercises ?? []).sorted { $0.order < $1.order }
    }

    private var isLastExercise: Bool {
        currentExerciseIndex >= sortedExercises.count - 1
    }

    static func totalSeconds(for plan: WorkoutPlan) -> Int {
        let exercises = (plan.exercises ?? []).sorted { $0.order < $1.order }
        let exerciseSeconds = exercises.reduce(0) { total, exercise in
            total + (exercise.duration * exercise.sets) + (exercise.restTime * max(0, exercise.sets - 1))
        }
        return exerciseSeconds + plan.restTimeAfterLastSet * max(0, exercises.count - 1)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
