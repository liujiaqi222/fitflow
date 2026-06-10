# AI Fitness Timer — 设计文档

> 日期：2026-06-10
> 状态：已审核

## 1. 项目概述

一款 iOS 原生健身训练计时应用。用户通过自然语言描述身体状态、运动目标和动作禁忌，AI 生成个性化动作清单，用户可编辑后开始训练。训练过程中，系统通过语音播报引导用户完成每个动作，训练结束后记录反馈用于优化后续计划。

### 核心流程

```
对话描述 → AI 生成动作清单 ↔ 编辑清单 ↔ 训练播放 ↔ 语音引导 ↔ 训练反馈
```

### 与参考项目的关系

参考项目（Customized Fitness Training App）是一个 React Web 应用，本项目全新开发，借鉴其功能设计和交互逻辑，但采用 Swift/SwiftUI 原生实现，并接入真实 AI API。

## 2. 技术决策

| 维度 | 决策 |
|------|------|
| 语言 | Swift |
| UI 框架 | SwiftUI |
| 最低版本 | iOS 17+ |
| 架构模式 | MVVM + Service Layer + WorkoutEngine |
| AI 集成 | 可插拔 AI 后端（protocol，支持 Claude/OpenAI/Mock） |
| 语音播报 | AVSpeechSynthesizer |
| 数据持久化 | SwiftData + iCloud |
| 包管理 | Swift Package Manager |

## 3. 架构

```
SwiftUI Views
├── HomeView
├── ChatPlanView
├── PlanEditorView
├── WorkoutPlayerView
├── FeedbackView
├── HistoryView
└── SettingsView

ViewModels
├── HomeViewModel
├── ChatPlanViewModel
├── PlanEditorViewModel
├── WorkoutPlayerViewModel
└── FeedbackViewModel

Services
├── AIService (protocol)
│   ├── ClaudeProvider
│   ├── OpenAIProvider
│   └── MockProvider
├── WorkoutEngine
├── SpeechService
├── LiveActivityService
├── ExerciseLibrary
└── PlanRepository

SwiftData Models
├── WorkoutPlan
├── ExerciseItem
├── WorkoutSession
└── WorkoutTemplate
```

## 4. 页面流程与导航

```
HomeView ──► ChatPlanView ──► PlanEditorView ──► WorkoutPlayerView ──► FeedbackView
   │                                                       │
   ├── HistoryView                                         │
   └── SettingsView                                        │
```

使用 NavigationStack + navigationDestination 实现线性流程为主，History 和 Settings 从 HomeView 进入。

### 4.1 HomeView

- 当前训练计划卡片（含动作标签和"开始训练"按钮）
- 最近一次训练摘要
- 快捷操作：AI 对话生成计划、从模板选择

### 4.2 ChatPlanView

- 聊天界面，用户输入自然语言描述身体状态和目标
- 快捷标签：膝盖不适、无跳跃、术后、上肢为主、坐姿、卧姿、有弹力带、15 分钟、温和动作
- AI 生成计划后展示为内联卡片预览
- "使用此计划"按钮进入 PlanEditorView

### 4.3 PlanEditorView

- 动作列表，支持拖拽排序
- 每个动作可编辑：组数、每组时长、休息时间
- 操作：删除动作、标记不适、替换为替代动作
- 动作要领和安全提醒可展开查看
- 统计栏：总时长、动作数、难度、不适标记数
- 保存为模板

### 4.4 WorkoutPlayerView

- 全屏计时器，环形进度条（SwiftUI Circle + trim）
- 显示：当前动作名、当前组数/总组数、倒计时、下一动作预览
- 已训练时间、预估剩余时间、整体进度
- 控制按钮：暂停/继续、跳过、延长休息（+30 秒）
- 灵动岛/锁屏 Live Activity 控制（暂停/继续、跳过）
- 语音播报模式切换
- 点状进度指示器（动作进度）
- 结束确认弹窗

### 4.5 FeedbackView

- 训练统计：时长、完成率、完成动作数
- 疲劳程度选择：轻松/适中/吃力/疼痛
- 疼痛评分滑块（0–10，选择"吃力"或"疼痛"时显示）
- 备注文本框
- 保存训练记录

### 4.6 HistoryView

- 两个 Tab：训练记录、我的模板
- 训练记录列表：完成百分比、疲劳表情、日期、时长
- 模板列表：一键加载
- 汇总统计：总训练次数、总时长、平均完成率

### 4.7 SettingsView

- AI 后端选择（Claude / OpenAI / Mock）
- API Key 配置
- 语音偏好（语速、音调、VoiceMode 默认值）
- 关于与反馈

## 5. WorkoutEngine — 训练播放引擎

WorkoutEngine 是核心组件，将动作清单转化为可播放的训练流程。

### 5.1 状态机

```
       ┌──────────────────────────────┐
       │                              │
       ▼                              │
[idle] ──start──► [exercise] ──set done──► [rest] ┘
          │              │                  │
          │              │ last set         │ timeUp
          │              ▼                  ▼
          │        [transition] ──timeUp──► [exercise] (next)
          │              │
          │              │ last exercise
          │              ▼
          └──────► [completed]
```

三种阶段（Phase）：

- **exercise**：执行动作，倒计时 `duration` 秒
- **rest**：组间休息，倒计时 `restTime` 秒
- **transition**：动作间过渡，固定 12 秒

### 5.2 状态属性

```swift
@Observable
class WorkoutEngine {
    // 当前状态
    var phase: Phase                  // .idle, .exercise, .rest, .transition, .completed
    var currentExerciseIndex: Int
    var currentSet: Int               // 当前第几组（1-based）
    var timeRemaining: Int            // 当前阶段剩余秒数
    var isRunning: Bool               // 暂停/继续

    // 进度信息
    var totalElapsed: Int             // 已训练总秒数
    var estimatedRemaining: Int       // 预估剩余秒数
    var overallProgress: Double       // 0.0 ~ 1.0

    // 记录
    var completedExerciseIds: Set<String>
    var skippedExerciseIds: Set<String>
}
```

### 5.3 关键方法

- `start(plan:)` — 加载动作清单并开始
- `pause()` / `resume()` — 暂停/继续
- `skip()` — 跳过当前动作
- `extendRest(seconds: 30)` — 延长休息时间
- `endWorkout()` — 提前结束训练

### 5.4 事件回调

```swift
func onPhaseChange(from: Phase, to: Phase)
func onExerciseStart(exercise: ExerciseItem, isFirstSet: Bool)
func onSetStart(exercise: ExerciseItem, setNumber: Int)
func onRestStart(nextExercise: ExerciseItem)
func onCountdown(seconds: Int)       // 3, 2, 1
func onTenSecondWarning()            // 剩余 10 秒
func onWorkoutComplete()
```

### 5.5 时间估算

```
per exercise = (duration × sets) + (restTime × (sets - 1)) + 12 (transition)
total        = sum of all exercises
```

## 6. AI Service 可插拔架构

### 6.1 Protocol

```swift
protocol AIService {
    func generatePlan(from userDescription: String) async throws -> WorkoutPlan
}
```

### 6.2 实现类

- **ClaudeProvider**：调用 Anthropic Claude API
- **OpenAIProvider**：调用 OpenAI GPT API
- **MockProvider**：本地规则引擎，开发/预览/降级用

### 6.3 Prompt 策略

将用户描述 + ExerciseLibrary 的结构化动作数据一起发给 AI，要求 AI 从动作库中选取并调整参数（组数、时长、休息时间），返回结构化 JSON。确保 AI 输出的动作都有正确的 `instructions`（动作要领）和 `safety`（安全提醒）字段。

### 6.4 降级策略

AI API 调用失败（网络/配额/Key 无效）时，自动降级到 MockProvider，保证用户始终能生成计划。

## 7. SpeechService 语音播报

### 7.1 VoiceMode

```swift
enum VoiceMode {
    case off        // 静音
    case first      // 仅每个动作第一组前播报动作要领
    case every      // 每组开始前都播报动作要领
    case rest       // 休息期间播报下一个动作要领
    case safety     // 仅播报安全提醒
}
```

### 7.2 播报时机

| 事件 | 播报内容 |
|------|---------|
| 训练开始 | "训练开始！[动作名]" |
| 动作首次开始 | 动作要领（instructions） |
| 每组开始 | "第 N 组，[动作名]，开始" |
| 剩余 10 秒 | "还剩 10 秒" |
| 3-2-1 倒计时 | "3"、"2"、"1" |
| 休息开始 | "休息 N 秒" + 下一动作要领（VoiceMode = .rest 时） |
| 动作切换 | "下一个，[动作名]" |
| 训练完成 | "训练完成！辛苦了，记得拉伸" |

### 7.3 动作要领播报逻辑

- `VoiceMode.first`：每个动作的第一组开始前，播报该动作的 instructions
- `VoiceMode.every`：每组开始前都播报 instructions
- `VoiceMode.rest`：组间休息期间，播报下一个动作的 instructions
- `VoiceMode.safety`：动作开始前播报 safety 安全提醒

### 7.4 实现

使用 AVSpeechSynthesizer，配置 zh-CN 语言，语速略慢（`rate: 0.9`），音调略高（`pitch: 1.05`）。

## 8. 后台播报与灵动岛

### 8.1 后台音频模式

训练进行中用户锁屏或切到其他 App 时，计时器和语音播报必须持续运行。

实现方案：

- **Audio Session 配置**：使用 AVAudioSession 设置 `.playback` 类别，确保系统不会挂起音频

  ```swift
  let session = AVAudioSession.sharedInstance()
  try session.setCategory(.playback, mode: .spokenAudio, options: .mixWithOthers)
  try session.setActive(true)
  ```

- **Background Modes**：在 Info.plist 中声明 audio 后台模式，使 App 在后台时仍可执行语音合成

- **后台计时器保活**：训练期间使用 `ProcessInfo.processInfo.performExpiringActivity` 或 BGProcessingTask 请求后台执行时间，防止系统挂起 WorkoutEngine 的计时器

- **生命周期处理**：
  - 进入后台：保持 WorkoutEngine 运行，SpeechService 继续播报
  - 返回前台：同步 UI 与引擎状态，无感知恢复
  - 内存警告/系统终止：在 scenePhase 变化时持久化当前训练状态到 SwiftData，下次启动可恢复

### 8.2 Live Activity & 灵动岛

训练期间在锁屏和灵动岛显示实时训练状态，用户无需打开 App 即可查看进度和操控训练。

显示内容：

| 状态 | 灵动岛（紧凑） | 灵动岛（展开） | 锁屏 Live Activity |
|------|---------------|---------------|-------------------|
| 运动中 | 动作名 + 倒计时 | 动作名、组数、环形进度、倒计时、下一动作 | 动作名、组数/总组数、倒计时、环形进度、控制按钮 |
| 休息中 | "休息" + 倒计时 | 休息倒计时、下一动作名、控制按钮 | 休息倒计时、下一动作、控制按钮 |
| 过渡中 | "准备" + 倒计时 | 下一个动作名、倒计时 | 下一个动作名、倒计时 |
| 暂停 | 动作名 + "已暂停" | 暂停状态、继续按钮 | 暂停状态、继续按钮 |

控制按钮（锁屏和灵动岛展开态）：

- 暂停/继续
- 跳过当前动作

技术实现：

```swift
// ActivityAttributes 定义
struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: Phase              // .exercise, .rest, .transition
        var exerciseName: String
        var currentSet: Int
        var totalSets: Int
        var timeRemaining: Int
        var isRunning: Bool
        var nextExerciseName: String?
    }
    var planName: String
}
```

LiveActivityService：

```swift
@Observable
class LiveActivityService {
    var currentActivity: Activity<WorkoutAttributes>?

    func start(plan: WorkoutPlan)                          // 训练开始时创建 Live Activity
    func update(state: WorkoutAttributes.ContentState)     // 每秒/状态变化时更新
    func end()                                             // 训练结束时关闭
}
```

更新频率：倒计时每秒更新一次。为避免系统限制更新频率，使用 `Activity.update()` 的 staleDate 机制，在灵动岛紧凑态仅显示动作名和相位，详细倒计时在展开态和锁屏显示。

WorkoutEngine 集成：引擎状态变化时同步更新 Live Activity

- `onPhaseChange` → 更新阶段和动作名
- `onSetStart` → 更新组数
- 每秒 tick → 更新 `timeRemaining`
- `pause()` / `resume()` → 更新 `isRunning`
- `onWorkoutComplete()` → 结束 Live Activity

灵动岛交互：通过 AppIntent 处理按钮点击事件，回调到 WorkoutEngine 执行暂停/跳过操作

## 9. 数据模型

### 9.1 WorkoutPlan

```swift
@Model
class WorkoutPlan {
    var id: UUID
    var name: String
    var exercises: [ExerciseItem]
    var createdAt: Date
    var source: PlanSource           // .aiGenerated, .manual, .template
    var userContext: String          // 用户描述原文
}
```

### 9.2 ExerciseItem

```swift
@Model
class ExerciseItem {
    var id: UUID
    var templateId: String           // 对应 ExerciseLibrary 中的模板
    var name: String
    var duration: Int                // 每组秒数
    var sets: Int
    var restTime: Int                // 组间休息秒数
    var instructions: String         // 动作要领
    var safety: String               // 安全提醒
    var difficulty: Difficulty       // .easy, .moderate
    var order: Int                   // 排序
}
```

### 9.3 WorkoutSession

```swift
@Model
class WorkoutSession {
    var id: UUID
    var date: Date
    var plan: WorkoutPlan?
    var completedExerciseIds: [String]
    var skippedExerciseIds: [String]
    var totalSeconds: Int
    var feeling: Feeling             // .easy, .moderate, .hard, .pain
    var painScore: Int               // 0–10
    var notes: String
}
```

### 9.4 WorkoutTemplate

```swift
@Model
class WorkoutTemplate {
    var id: UUID
    var name: String
    var exercises: [ExerciseItem]
    var createdAt: Date
}
```

## 10. 枚举定义

```swift
enum PlanSource: String, Codable {
    case aiGenerated
    case manual
    case template
}

enum Difficulty: String, Codable {
    case easy
    case moderate
}

enum Feeling: String, Codable {
    case easy
    case moderate
    case hard
    case pain
}

enum Phase {
    case idle
    case exercise
    case rest
    case transition
    case completed
}
```

## 11. ExerciseLibrary 内置动作库

内置 16+ 个动作模板，每个包含：

- `id`：唯一标识
- `name`：中文名称
- `duration`：默认每组秒数
- `sets`：默认组数
- `restTime`：默认休息秒数
- `instructions`：动作要领（中文）
- `safety`：安全提醒（中文）
- `difficulty`：难度
- `categories`：分类标签（chair / bed / knee-friendly / lower / upper / core / band / standing）
- `alternatives`：替代动作 ID 列表

动作库供 AI 选取和 MockProvider 降级使用。

## 12. 错误处理

| 场景 | 处理方式 |
|------|---------|
| AI API 调用失败 | 降级到 MockProvider，显示提示 |
| 网络不可用 | 使用 MockProvider，提示离线模式 |
| API Key 未配置 | 引导用户前往 SettingsView 配置 |
| 语音合成不可用 | 静默降级，仅视觉提示 |
| 训练中 App 进入后台 | 保持计时器和语音运行，Live Activity 持续更新 |
| 训练中 App 被系统终止 | 持久化训练状态，下次启动恢复 |
| 训练中来电/中断 | 暂停训练，用户返回后可继续 |
| Live Activity 不可用（旧机型） | 静默降级，仅使用通知和后台音频 |

## 13. 非功能需求

- **性能**：计时器精度 ±0.1 秒，不因 UI 更新而漂移
- **后台**：支持后台音频模式，训练中锁屏仍可接收语音播报和 Live Activity 更新
- **灵动岛**：iPhone 14 Pro 及以上支持灵动岛实时显示，旧机型支持锁屏 Live Activity
- **无障碍**：VoiceOver 支持，动态字体
- **国际化**：首版中文，架构预留多语言
- **最低版本**：iOS 17+（ActivityKit 从 iOS 16.1 可用，iOS 17+ 确保 SwiftData 和 @Observable 兼容）
