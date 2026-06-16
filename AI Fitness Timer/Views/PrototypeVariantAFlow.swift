import SwiftUI

// MARK: - Plan Editor (编辑计划)

struct VariantAPlanEditor: View {
    @State private var showSafety: Int? = nil
    @Environment(\.dismiss) private var dismiss

    // Mock data
    @State private var exercises: [PlanExerciseItem] = [
        PlanExerciseItem(name: "椅子深蹲", sets: 3, duration: 30, restTime: 30, difficulty: .easy, instructions: "双脚与肩同宽，臀部向后轻触椅面后站起。", safety: "膝盖保持朝向脚尖，疼痛时减小幅度。"),
        PlanExerciseItem(name: "床上臀桥", sets: 3, duration: 40, restTime: 30, difficulty: .easy, instructions: "仰卧屈膝，收紧臀部抬髋到肩髋膝成一直线。", safety: "腰部不反弓，颈部放松。"),
        PlanExerciseItem(name: "坐姿抬腿", sets: 2, duration: 45, restTime: 25, difficulty: .easy, instructions: "坐稳后交替抬膝，保持躯干直立。", safety: "避免憋气，腰背不适时降低抬腿高度。"),
        PlanExerciseItem(name: "踝泵", sets: 2, duration: 45, restTime: 20, difficulty: .easy, instructions: "坐姿或卧姿，脚尖向前绷直再回勾。", safety: "动作轻柔，避免疼痛范围。"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats bar
                statsBar

                // Exercise list
                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    exerciseCard(index: index, exercise: exercise)
                }

                // Save as template
                Button {
                    // Prototype — no-op
                } label: {
                    Label("保存为模板", systemImage: "square.and.arrow.down")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                // Start workout CTA
                NavigationLink {
                    VariantAWorkoutPlayer()
                } label: {
                    Text("开始训练")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("编辑计划")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statItem(value: "\(totalMinutes)", unit: "分钟")
            Divider().frame(height: 28)
            statItem(value: "\(exercises.count)", unit: "动作")
            Divider().frame(height: 28)
            statItem(value: "简单", unit: "难度")
        }
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.orange)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var totalMinutes: Int {
        let seconds = exercises.reduce(0) { total, ex in
            total + (ex.duration * ex.sets) + (ex.restTime * max(0, ex.sets - 1))
        }
        return (seconds + 20 * max(0, exercises.count - 1)) / 60
    }

    // MARK: - Exercise Card

    private func exerciseCard(index: Int, exercise: PlanExerciseItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)

                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                // Difficulty badge
                Text(exercise.difficulty == .easy ? "简单" : "中等")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(exercise.difficulty == .easy ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                    .foregroundStyle(exercise.difficulty == .easy ? .green : .orange)
                    .clipShape(Capsule())

                // Discomfort button
                Button {
                    // Prototype — mark as discomfort
                } label: {
                    Image(systemName: "hand.raised.fill")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.6))
                }
            }

            // Editable parameters
            HStack(spacing: 16) {
                parameterControl(label: "组数", value: exercise.sets, range: 1...10) {
                    exercises[index].sets = $0
                }
                parameterControl(label: "时长", value: exercise.duration, range: 10...120, unit: "s") {
                    exercises[index].duration = $0
                }
                parameterControl(label: "休息", value: exercise.restTime, range: 10...120, unit: "s") {
                    exercises[index].restTime = $0
                }
            }

            // Expandable instructions / safety
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.instructions)
                        .font(.caption)
                    Label(exercise.safety, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.top, 4)
            } label: {
                Text("要领与安全提醒")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Actions
            HStack {
                Button {
                    // Prototype — replace
                } label: {
                    Label("替换", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Button(role: .destructive) {
                    withAnimation { _ = exercises.remove(at: index) }
                } label: {
                    Label("删除", systemImage: "trash")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func parameterControl(label: String, value: Int, range: ClosedRange<Int>, unit: String = "", onChange: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Button { onChange(max(range.lowerBound, value - 1)) } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(value)\(unit)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 32)
                Button { onChange(min(range.upperBound, value + 1)) } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Workout Player (训练播放)

struct VariantAWorkoutPlayer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPaused = false
    @State private var showEndConfirmation = false
    @State private var navigateToFeedback = false
    @State private var voiceMode: VoiceMode = .first
    @State private var timeRemaining = 25  // seconds in current phase
    @State private var currentSet = 1
    @State private var totalElapsed = 0

    // Mock current exercise
    private let currentExercise = PlanExerciseItem(name: "椅子深蹲", sets: 3, duration: 30, restTime: 30, difficulty: .easy, instructions: "双脚与肩同宽，臀部向后轻触椅面后站起。", safety: "膝盖保持朝向脚尖，疼痛时减小幅度。")
    private let nextExercise = PlanExerciseItem(name: "床上臀桥", sets: 3, duration: 40, restTime: 30, difficulty: .easy, instructions: "仰卧屈膝，收紧臀部抬髋到肩髋膝成一直线。", safety: "腰部不反弓，颈部放松。")

    // Dot indicators
    private let totalExercises = 4
    @State private var currentExerciseIndex = 0

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Phase label
                phaseLabel

                Spacer().frame(height: 20)

                // Ring timer
                ringTimer

                Spacer().frame(height: 12)

                // Exercise name + set info
                exerciseInfo

                Spacer().frame(height: 8)

                // Next exercise preview
                nextExercisePreview

                Spacer().frame(height: 20)

                // Dot progress
                dotProgress

                Spacer()

                // Elapsed / remaining
                timeStats

                Spacer().frame(height: 24)

                // Controls
                controls

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
        .confirmationDialog("确定结束训练？", isPresented: $showEndConfirmation, titleVisibility: .visible) {
            Button("结束训练", role: .destructive) {
                navigateToFeedback = true
            }
            Button("继续训练", role: .cancel) {}
        } message: {
            Text("训练数据会保存到历史记录")
        }
        .navigationDestination(isPresented: $navigateToFeedback) {
            VariantAFeedback()
        }
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        Text("运动中")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(.orange)
            .clipShape(Capsule())
    }

    // MARK: - Ring Timer

    private var ringTimer: some View {
        ZStack {
            // Background ring
            Circle()
                .strokeBorder(Color(.systemGray5), lineWidth: 12)
                .frame(width: 220, height: 220)

            // Progress ring
            Circle()
                .trim(from: 0, to: progressRatio)
                .stroke(.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))

            // Time display
            VStack(spacing: 4) {
                Text(formatTime(timeRemaining))
                    .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                Text(isPaused ? "已暂停" : "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var progressRatio: CGFloat {
        guard currentExercise.duration > 0 else { return 0 }
        return CGFloat(currentExercise.duration - timeRemaining) / CGFloat(currentExercise.duration)
    }

    // MARK: - Exercise Info

    private var exerciseInfo: some View {
        VStack(spacing: 6) {
            Text(currentExercise.name)
                .font(.title2.weight(.bold))

            HStack(spacing: 4) {
                ForEach(1...currentExercise.sets, id: \.self) { set in
                    Circle()
                        .fill(set <= currentSet ? Color.orange : Color(.systemGray5))
                        .frame(width: 10, height: 10)
                }
            }

            Text("第 \(currentSet) 组 / 共 \(currentExercise.sets) 组")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Next Preview

    private var nextExercisePreview: some View {
        HStack(spacing: 8) {
            Image(systemName: "forward.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("下一个：\(nextExercise.name)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Dot Progress

    private var dotProgress: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalExercises, id: \.self) { i in
                if i == currentExerciseIndex {
                    Circle()
                        .fill(.orange)
                        .frame(width: 10, height: 10)
                } else if i < currentExerciseIndex {
                    Circle()
                        .fill(.orange.opacity(0.4))
                        .frame(width: 10, height: 10)
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }

    // MARK: - Time Stats

    private var timeStats: some View {
        HStack {
            VStack(spacing: 2) {
                Text(formatTime(totalElapsed))
                    .font(.title3.weight(.medium).monospacedDigit())
                Text("已训练")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Overall progress
            VStack(spacing: 2) {
                Text("25%")
                    .font(.title3.weight(.medium))
                Text("总进度")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("10:30")
                    .font(.title3.weight(.medium).monospacedDigit())
                Text("预估剩余")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            // Primary row
            HStack(spacing: 20) {
                // Skip
                controlButton(icon: "forward.end.fill", label: "跳过") {
                    // Prototype — no-op
                }

                // Pause / Resume
                Button {
                    isPaused.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.orange)
                            .frame(width: 72, height: 72)
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                }

                // Extend rest
                controlButton(icon: "clock.badge.plus", label: "+30s") {
                    // Prototype — extend rest
                }
                .opacity(false ? 1 : 0.4) // would check if phase == .rest
            }

            // Secondary row
            HStack(spacing: 0) {
                // Voice mode
                Menu {
                    ForEach(VoiceMode.allCases, id: \.self) { mode in
                        Button {
                            voiceMode = mode
                        } label: {
                            Label(voiceModeLabel(mode), systemImage: voiceMode == mode ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text(voiceModeShortLabel(voiceMode))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // End workout
                Button {
                    showEndConfirmation = true
                } label: {
                    Text("结束训练")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func controlButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.primary)
            .frame(width: 64, height: 64)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func voiceModeLabel(_ mode: VoiceMode) -> String {
        switch mode {
        case .off: return "静音"
        case .first: return "仅首次"
        case .every: return "每组"
        case .rest: return "休息时"
        case .safety: return "仅安全提醒"
        }
    }

    private func voiceModeShortLabel(_ mode: VoiceMode) -> String {
        switch mode {
        case .off: return "静音"
        case .first: return "首次"
        case .every: return "每组"
        case .rest: return "休息"
        case .safety: return "安全"
        }
    }
}

// MARK: - Feedback (训练反馈)

struct VariantAFeedback: View {
    @State private var feeling: Feeling = .easy
    @State private var painScore: Double = 0
    @State private var notes = ""
    @State private var showPainAlert = false
    @Environment(\.dismiss) private var dismiss

    // Mock skipped exercises
    private let skippedExercises = ["墙壁俯卧撑"]
    private let completedCount = 3
    private let totalExercises = 4
    private let totalSeconds = 720  // 12 minutes

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Celebration
                celebrationSection

                // Stats
                statsSection

                // Feeling
                feelingSection

                // Pain score (conditional)
                if feeling == .hard || feeling == .pain {
                    painSection
                }

                // Skipped exercises (conditional)
                if !skippedExercises.isEmpty {
                    skippedSection
                }

                // Notes
                notesSection

                // Save
                Button {
                    // Prototype — save & go home
                } label: {
                    Text("保存训练记录")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("训练完成")
        .navigationBarTitleDisplayMode(.inline)
        .alert("是否将「墙壁俯卧撑」加入禁忌？", isPresented: $showPainAlert) {
            Button("加入禁忌") {
                // Write to HealthProfile.contraindications
            }
            Button("不了", role: .cancel) {}
        } message: {
            Text("加入后 AI 生成计划时会自动避开该动作")
        }
    }

    // MARK: - Celebration

    private var celebrationSection: some View {
        VStack(spacing: 8) {
            Text("🎉")
                .font(.system(size: 48))
            Text("训练完成！辛苦了")
                .font(.title3.weight(.semibold))
            Text("记得拉伸放松")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(formatTime(totalSeconds))
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                Text("训练时长")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 32)

            VStack(spacing: 4) {
                Text("\(Int(Double(completedCount) / Double(totalExercises) * 100))%")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.orange)
                Text("完成率")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 32)

            VStack(spacing: 4) {
                Text("\(completedCount)/\(totalExercises)")
                    .font(.title2.weight(.bold))
                Text("完成动作")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Feeling

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("感觉如何？")
                .font(.headline)

            HStack(spacing: 10) {
                feelingOption(.easy, emoji: "😊", label: "轻松")
                feelingOption(.moderate, emoji: "😐", label: "适中")
                feelingOption(.hard, emoji: "😣", label: "吃力")
                feelingOption(.pain, emoji: "🤕", label: "疼痛")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func feelingOption(_ value: Feeling, emoji: String, label: String) -> some View {
        Button {
            feeling = value
            if value == .pain && painScore >= 6 {
                showPainAlert = true
            }
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.title)
                Text(label)
                    .font(.caption2.weight(feeling == value ? .bold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(feeling == value ? Color.orange.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(feeling == value ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Pain Score

    private var painSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("疼痛评分")
                .font(.headline)

            HStack {
                Text("0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $painScore, in: 0...10, step: 1) {
                    Text("疼痛评分")
                } minimumValueLabel: {
                    Text("0").font(.caption2).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("10").font(.caption2).foregroundStyle(.secondary)
                }
                .tint(painScore >= 6 ? .red : .orange)
                .onChange(of: Int(painScore)) { _, newValue in
                    if newValue >= 6 {
                        showPainAlert = true
                    }
                }
            }

            Text("当前：\(Int(painScore)) / 10")
                .font(.caption)
                .foregroundStyle(painScore >= 6 ? .red : .secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Skipped

    private var skippedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("跳过的动作")
                .font(.headline)

            ForEach(skippedExercises, id: \.self) { name in
                HStack {
                    Image(systemName: "forward.end.fill")
                        .foregroundStyle(.orange)
                    Text(name)
                        .font(.subheadline)
                    Spacer()
                    NavigationLink {
                        Text("健身档案")  // Would link to HealthProfileView
                    } label: {
                        Text("调整档案")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.headline)

            TextField("记录训练感受（仅本地存储）", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Data Model for Prototype

struct PlanExerciseItem {
    var name: String
    var sets: Int
    var duration: Int
    var restTime: Int
    var difficulty: Difficulty
    var instructions: String
    var safety: String
}
