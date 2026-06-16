import SwiftUI

struct WorkoutEngineCheckpointView: View {
    private let engine = WorkoutEngine(clock: SystemAppClock())
    private let plan = Self.demoPlan()

    @State private var phase: Phase = .idle
    @State private var currentSet = 1
    @State private var timeRemaining = 0
    @State private var isRunning = false
    @State private var progress = 0.0
    @State private var currentExerciseName = "坐姿抬膝"

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                Text("第 \(currentSet) 组")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.18), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: max(0, min(1, progress)))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(timeRemaining)")
                    .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
            }
            .frame(width: 230, height: 230)

            HStack {
                Button(isRunning ? "暂停" : "继续") {
                    Task {
                        if await engine.isRunning {
                            await engine.pause()
                        } else {
                            await engine.resume()
                        }
                        await refresh()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("+30秒") {
                    Task {
                        await engine.extendRest(seconds: 30)
                        await refresh()
                    }
                }
                .buttonStyle(.bordered)

                Button("跳过") {
                    Task {
                        await engine.skip()
                        await refresh()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationTitle("计时器预览")
        .task {
            await engine.start(plan: plan)
            await refreshLoop()
        }
    }

    private var title: String {
        switch phase {
        case .idle:
            "准备开始"
        case .exercise:
            currentExerciseName
        case .rest:
            "休息"
        case .completed:
            "训练完成"
        }
    }

    private func refreshLoop() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func refresh() async {
        phase = await engine.phase
        currentSet = await engine.currentSet
        timeRemaining = await engine.timeRemaining
        isRunning = await engine.isRunning
        progress = await engine.overallProgress
        currentExerciseName = plan.exercises?.first?.name ?? "训练"
    }

    private static func demoPlan() -> WorkoutPlan {
        let template = ExerciseTemplate(
            id: "checkpoint_seated_knee_raise",
            name: "坐姿抬膝",
            duration: 20,
            sets: 2,
            restTime: 10,
            instructions: "坐稳后交替抬膝，保持呼吸平稳。",
            safety: "如果膝盖疼痛，立即停止。",
            difficulty: .easy,
            categories: ["lower-body", "seated"],
            alternatives: []
        )

        return WorkoutPlan(
            name: "计时器预览",
            exercises: [
                ExerciseItem(template: template, sets: 2, duration: 20, restTime: 10, order: 0)
            ],
            restTimeAfterLastSet: 10
        )
    }
}
