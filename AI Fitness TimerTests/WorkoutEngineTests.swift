import XCTest
@testable import AI_Fitness_Timer

final class WorkoutEngineTests: XCTestCase {
    func testCompletesTwoSetWorkoutWithRest() async throws {
        let clock = MockAppClock()
        let engine = WorkoutEngine(clock: clock)
        let plan = makePlan(duration: 2, sets: 2, rest: 1)

        await engine.start(plan: plan)

        var phase = await engine.phase
        let currentExerciseIndex = await engine.currentExerciseIndex
        var currentSet = await engine.currentSet
        var timeRemaining = await engine.timeRemaining
        XCTAssertEqual(phase, .exercise)
        XCTAssertEqual(currentExerciseIndex, 0)
        XCTAssertEqual(currentSet, 1)
        XCTAssertEqual(timeRemaining, 2)

        await advance(engine, clock, by: 2)
        phase = await engine.phase
        currentSet = await engine.currentSet
        timeRemaining = await engine.timeRemaining
        XCTAssertEqual(phase, .rest)
        XCTAssertEqual(currentSet, 1)
        XCTAssertEqual(timeRemaining, 1)

        await advance(engine, clock, by: 1)
        phase = await engine.phase
        currentSet = await engine.currentSet
        timeRemaining = await engine.timeRemaining
        XCTAssertEqual(phase, .exercise)
        XCTAssertEqual(currentSet, 2)
        XCTAssertEqual(timeRemaining, 2)

        await advance(engine, clock, by: 2)
        phase = await engine.phase
        let isRunning = await engine.isRunning
        timeRemaining = await engine.timeRemaining
        let completedExerciseIds = await engine.completedExerciseIds
        XCTAssertEqual(phase, .completed)
        XCTAssertFalse(isRunning)
        XCTAssertEqual(timeRemaining, 0)
        XCTAssertEqual(completedExerciseIds, ["exercise_0"])
    }

    func testPauseFreezesTimeRemaining() async throws {
        let clock = MockAppClock()
        let engine = WorkoutEngine(clock: clock)
        let plan = makePlan(duration: 10, sets: 1, rest: 5)

        await engine.start(plan: plan)
        await advance(engine, clock, by: 3)
        var timeRemaining = await engine.timeRemaining
        XCTAssertEqual(timeRemaining, 7)

        await engine.pause()
        var isRunning = await engine.isRunning
        XCTAssertFalse(isRunning)

        await clock.advance(seconds: 5)
        await Task.yield()
        timeRemaining = await engine.timeRemaining
        XCTAssertEqual(timeRemaining, 7)

        await engine.resume()
        isRunning = await engine.isRunning
        XCTAssertTrue(isRunning)

        await advance(engine, clock, by: 2)
        timeRemaining = await engine.timeRemaining
        XCTAssertEqual(timeRemaining, 5)
    }

    func testExtendRestOnlyWorksInRest() async throws {
        let clock = MockAppClock()
        let engine = WorkoutEngine(clock: clock)
        let plan = makePlan(duration: 1, sets: 2, rest: 5)

        await engine.start(plan: plan)
        await engine.extendRest()
        var phase = await engine.phase
        var timeRemaining = await engine.timeRemaining
        XCTAssertEqual(phase, .exercise)
        XCTAssertEqual(timeRemaining, 1)

        await advance(engine, clock, by: 1)
        phase = await engine.phase
        timeRemaining = await engine.timeRemaining
        XCTAssertEqual(phase, .rest)
        XCTAssertEqual(timeRemaining, 5)

        await engine.extendRest()
        timeRemaining = await engine.timeRemaining
        XCTAssertEqual(timeRemaining, 35)
    }

    private func makePlan(duration: Int, sets: Int, rest: Int, exerciseCount: Int = 1) -> WorkoutPlan {
        let exercises = (0..<exerciseCount).map { index in
            let template = ExerciseTemplate(
                id: "exercise_\(index)",
                name: "动作\(index)",
                duration: duration,
                sets: sets,
                restTime: rest,
                instructions: "说明",
                safety: "安全",
                difficulty: .easy,
                categories: [],
                alternatives: []
            )
            return ExerciseItem(template: template, sets: sets, duration: duration, restTime: rest, order: index)
        }

        return WorkoutPlan(name: "测试", exercises: exercises, restTimeAfterLastSet: rest)
    }

    private func advance(_ engine: WorkoutEngine, _ clock: MockAppClock, by seconds: Int) async {
        for _ in 0..<seconds {
            let previousElapsed = await engine.totalElapsed

            for _ in 0..<20 {
                await Task.yield()
                await clock.advance(seconds: 1)
                await Task.yield()

                if await engine.totalElapsed > previousElapsed {
                    break
                }
            }
        }
    }
}
