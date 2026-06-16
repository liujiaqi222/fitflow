import SwiftUI
import SwiftData

// MARK: - Variant A: 卡片中心 (Card-Centered Dashboard)
//
// 大卡片、圆角、阴影，信息密度适中。
// 首页以卡片展示当前计划、最近训练、快捷操作。
// 3 个 Tab：训练 / 历史 / 我的
// AI 对话是训练首页的子页面（NavigationLink push）

struct VariantAHome: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            VariantATrainTab()
                .tabItem { Label("训练", systemImage: "flame.fill") }
                .tag(0)

            VariantAHistoryTab()
                .tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }
                .tag(1)

            VariantAMeTab()
                .tabItem { Label("我的", systemImage: "person.fill") }
                .tag(2)
        }
        .tint(.orange)
    }
}

// MARK: - Tab 1: 训练 (Home + Chat as sub-page)

struct VariantATrainTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    greetingSection

                    // Current Plan
                    currentPlanCard

                    // Quick Actions — AI 对话 is primary
                    quickActionsRow

                    // Recent Session
                    recentSessionCard

                    // Today's Suggestion
                    suggestionCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AI Fitness Timer")
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("下午好 👋")
                .font(.title.weight(.bold))
            Text("今天想练什么？")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var currentPlanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("当前计划")
                    .font(.headline)
                Spacer()
                Text("膝盖友好")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }

            // Exercise chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["椅子深蹲", "床上臀桥", "坐姿抬腿", "墙壁俯卧撑"], id: \.self) { name in
                        Text(name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
            }

            HStack {
                Label("4 动作", systemImage: "figure.walk")
                Spacer()
                Label("15 分钟", systemImage: "clock")
                Spacer()
                Label("简单", systemImage: "heart")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            NavigationLink {
                VariantAWorkoutPlayer()
            } label: {
                Text("开始训练")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            // 定制训练 — primary action, navigates to chat sub-page
            NavigationLink {
                VariantAChatPage()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("定制训练")
                        .font(.caption.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }

            NavigationLink {
                VariantAPlanEditor()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("从模板")
                        .font(.caption.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
        }
    }

    private var recentSessionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近训练")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("上肢恢复训练")
                        .font(.subheadline.weight(.medium))
                    Text("昨天 · 12 分钟")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("75%")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.orange)
            }

            ProgressView(value: 0.75)
                .tint(.orange)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var suggestionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("今日推荐")
                    .font(.caption.weight(.semibold))
                Text("根据你的档案，建议做 15 分钟低冲击训练")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - AI 对话 (Sub-page, pushed from Home)

struct VariantAChatPage: View {
    @State private var inputText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    assistantBubble("你好！我是你的 AI 健身教练 🏋️\n告诉我你的身体状况和训练目标，我来帮你制定计划。")
                    userBubble("我膝盖不太好，想做一些低冲击的训练")
                    assistantBubble("了解！我会避免跳跃和深蹲类动作。你希望训练多长时间？")
                    userBubble("15 分钟左右")
                    assistantPlanBubble
                }
                .padding()
            }

            Divider()

            // Quick Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["膝盖不适", "无跳跃", "术后", "上肢为主", "坐姿", "15 分钟", "温和动作"], id: \.self) { tag in
                        Button {
                            inputText = tag
                        } label: {
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Input
            HStack(spacing: 12) {
                TextField("描述你的训练需求...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                Button {
                    // Prototype — no-op
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
            }
            .padding()
        }
        .navigationTitle("AI 对话")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func assistantBubble(_ text: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.subheadline)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 60)
        }
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 60)
            Text(text)
                .font(.subheadline)
                .padding(12)
                .background(.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var assistantPlanBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("已为你生成训练计划：")
                    .font(.subheadline)

                // Plan Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("🦵 膝盖友好下肢训练")
                        .font(.headline)

                    ForEach(["椅子深蹲 × 3组", "床上臀桥 × 3组", "坐姿抬腿 × 2组", "踝泵 × 2组"], id: \.self) { ex in
                        HStack {
                            Circle().fill(.orange).frame(width: 6, height: 6)
                            Text(ex).font(.caption)
                        }
                    }

                    HStack {
                        Label("4 动作", systemImage: "figure.walk").font(.caption2)
                        Spacer()
                        Label("15 分钟", systemImage: "clock").font(.caption2)
                    }
                    .foregroundStyle(.secondary)

                    NavigationLink("使用此计划") {
                        VariantAPlanEditor()
                    }
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(12)
                .background(.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 40)
        }
    }
}

// MARK: - Tab 2: 历史

struct VariantAHistoryTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("训练记录") {
                    ForEach(0..<5, id: \.self) { i in
                        HStack {
                            Circle()
                                .fill(i % 3 == 0 ? Color.orange : Color.green)
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading) {
                                Text("训练 \(i + 1)")
                                    .font(.subheadline.weight(.medium))
                                Text("\(i + 1) 天前 · \(10 + i * 3) 分钟")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(70 + i * 5)%")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Section("我的模板") {
                    ForEach(["膝盖友好", "上肢恢复", "核心稳定"], id: \.self) { name in
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.blue)
                            Text(name)
                        }
                    }
                }

                Section("汇总") {
                    HStack {
                        StatCard(value: "12", label: "总训练")
                        StatCard(value: "3.5h", label: "总时长")
                        StatCard(value: "82%", label: "完成率")
                    }
                }
            }
            .navigationTitle("历史")
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.orange)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab 3: 我的 (档案 + 设置)

struct VariantAMeTab: View {
    @State private var provider = "mock"

    var body: some View {
        NavigationStack {
            List {
                // Health Profile — inline
                Section("健身档案") {
                    NavigationLink {
                        VariantAProfileDetail()
                    } label: {
                        Label("身体状态与禁忌", systemImage: "heart.text.square.fill")
                    }

                    HStack {
                        Text("膝盖术后恢复中")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text("3 禁忌")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }

                // Settings — inline
                Section("设置") {
                    Picker("AI 后端", selection: $provider) {
                        Text("Mock (开发)").tag("mock")
                        Text("Claude").tag("claude")
                        Text("OpenAI").tag("openai")
                    }

                    NavigationLink {
                        Text("语音设置")
                    } label: {
                        Label("语音偏好", systemImage: "speaker.wave.2.fill")
                    }

                    NavigationLink {
                        Text("关于")
                    } label: {
                        Label("关于与反馈", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}

// MARK: - Profile Detail (Sub-page)

struct VariantAProfileDetail: View {
    var body: some View {
        List {
            Section("身体状态") {
                Text("膝盖术后恢复中，避免深蹲和跳跃")
                    .font(.subheadline)
            }

            Section("动作禁忌") {
                ForEach(["深蹲", "跳跃", "高冲击有氧"], id: \.self) { item in
                    HStack {
                        Text(item)
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red.opacity(0.6))
                    }
                }
            }

            Section("目标偏好") {
                ForEach(["康复", "柔韧", "心肺"], id: \.self) { goal in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text(goal)
                    }
                }
            }

            Section("伤病史") {
                Text("2025 年右膝半月板手术")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("清空档案", role: .destructive) {}
            }
        }
        .navigationTitle("健身档案")
        .navigationBarTitleDisplayMode(.inline)
    }
}
