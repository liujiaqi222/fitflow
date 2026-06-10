# AI Fitness Timer — 设计文档（V2 打磨版）

> 日期：2026-06-10
> 状态：已审核（V2 — superpowers 打磨）
> 前一版：`docs/AI Fitness Timer — 设计文档.md`

## 0. 版本说明

本版本在 V1 基础上修正了以下问题：架构级矛盾（ChatPlanView vs AIService 协议、WorkoutEngine 状态机不一致）、iOS 平台错误用法（后台保活 API、Live Activity 更新策略、AVAudioSession 配置）、安全/隐私缺口（API Key 存储、iCloud 同步范围）、产品价值闭环缺失（不适信号 → AI 生成）、可维护性缺口（测试策略）。

详细决策记录见文末附录 A。

## 1. 项目概述

一款 iOS 原生健身训练计时应用。用户通过自然语言描述身体状态、运动目标和动作禁忌，AI 生成个性化动作清单，用户可编辑后开始训练。训练过程中，系统通过语音播报引导用户完成每个动作，训练结束后记录反馈用于优化后续计划。

### 核心流程

```
对话生成（多轮）↔ 编辑清单 ↔ 训练播放 ↔ 语音引导 ↔ 训练反馈 ↔ 健身档案更新
```

### 产品差异化

「记住你的限制」：通过 HealthProfile 把每次训练中的不适标记、跳过行为、疼痛反馈持久化为用户档案，每次 AI 生成时作为 system context 注入，避免每次都靠用户重新描述。这是区别于「通用 ChatGPT 健身教练」的核心价值。

### 与参考项目的关系

参考项目（Customized Fitness Training App）是一个 React Web 应用，本项目全新开发，借鉴其功能设计和交互逻辑，但采用 Swift/SwiftUI 原生实现，并接入真实 AI API。

## 2. 技术决策

| 维度 | 决策 |
|------|------|
| 语言 | Swift |
| UI 框架 | SwiftUI |
| 最低版本 | iOS 17+ |
| 架构模式 | MVVM + Service Layer + WorkoutEngine |
| AI 集成 | 可插拔 AI 后端（protocol，支持 Claude/OpenAI/Mock），默认 Mock |
| 语音播报 | AVSpeechSynthesizer |
| 数据持久化 | SwiftData + CloudKit（敏感字段本地） |
| 密钥存储 | Keychain（SecretsStore 封装） |
| 后台运行 | Background Modes (audio) + 持续 AVAudioSession + 静音音频保活 |
| Live Activity | ActivityKit，事件驱动 + 系统计时渲染 |
| 包管理 | Swift Package Manager |
| 时间抽象 | Clock protocol（可注入，测试用 MockClock） |

## 3. 架构

```
SwiftUI Views
├── HomeView
├── ChatPlanView
├── PlanEditorView
├── WorkoutPlayerView
├── FeedbackView
├── HistoryView
├── HealthProfileView           // [新增]
└── SettingsView

ViewModels
├── HomeViewModel
├── ChatPlanViewModel
├── PlanEditorViewModel
├── WorkoutPlayerViewModel
├── FeedbackViewModel
└── HealthProfileViewModel       // [新增]

Services
├── AIService (protocol)
│   ├── ClaudeProvider
│   ├── OpenAIProvider
│   └── MockProvider
├── WorkoutEngine
├── SpeechService
├── AudioSessionController       // [新增] 管理 AVAudioSession 生命周期
├── SilentAudioKeepalive         // [新增] VoiceMode.off 时的后台保活
├── LiveActivityService
├── ExerciseLibrary
├── PlanRepository
├── HealthProfileStore           // [新增] HealthProfile 读写 + prompt 序列化
├── SecretsStore                 // [新增] Keychain 封装
├── WorkoutResumeStore           // [新增] 中断恢复
└── Clock (protocol)             // [新增] 时间抽象

SwiftData Models
├── WorkoutPlan
├── ExerciseItem
├── WorkoutSession
├── WorkoutTemplate
└── HealthProfile                // [新增，本地存储]
```

## 4. 页面流程与导航

```
HomeView ──► ChatPlanView ──► PlanEditorView ──► WorkoutPlayerView ──► FeedbackView
   │  ▲                                                                       │
   │  └───────────────── (HealthProfile 更新) ◄────────────────────────────────┘
   ├── HistoryView
   ├── HealthProfileView
   └── SettingsView
```

使用 NavigationStack + navigationDestination 实现线性流程为主。HomeView 启动时检查 WorkoutResumeStore，若存在 30 分钟内未完成的训练，弹窗询问「恢复 / 放弃」。

### 4.1 HomeView

- 当前训练计划卡片（含动作标签和「开始训练」按钮）
- 最近一次训练摘要
- 快捷操作：AI 对话生成计划、从模板选择
- 启动时执行未完成训练检查（见 §12.2）

### 4.2 ChatPlanView（已重写）

**多轮对话界面**，对话流形态：

- 顶部消息流：user / assistant 气泡按时间排列
- 底部输入区：文本框 + 快捷标签滚动条 + 发送按钮
- 快捷标签：膝盖不适、无跳跃、术后、上肢为主、坐姿、卧姿、有弹力带、15 分钟、温和动作。点击后**作为预填文本插入输入框**，用户可继续编辑后发送
- 计划卡片：当 AI 响应包含合法的 plan JSON 时，在 assistant 气泡位置渲染为可交互的内联卡片（显示动作列表、总时长、动作数）
- 用户可以继续追问（如「把跳跃换掉」「加 5 分钟核心」），AI 基于完整对话历史 + 上一份 plan 生成新版本
- **历史卡片不删除**，新卡片追加在新 assistant 消息处，方便用户对比和回退
- 每张卡片底部有「使用此计划」按钮，点击进入 PlanEditorView，传入对应的 plan

**会话状态**：ChatPlanViewModel 维护 `[ChatMessage]`，其中 ChatMessage 包含 role / text / plan?（可选关联的 plan）/ timestamp。会话不持久化（仅在当前导航 stack 中存活），离开 ChatPlanView 后丢弃。

### 4.3 PlanEditorView

- 动作列表，支持拖拽排序
- 每个动作可编辑：组数、每组时长、休息时间
- 操作：删除动作、**标记不适**（写入 HealthProfile.disliked 列表）、替换为替代动作（从 ExerciseLibrary.alternatives 选取）
- 动作要领和安全提醒可展开查看
- 统计栏：总时长、动作数、难度、不适标记数
- 保存为模板

### 4.4 WorkoutPlayerView

- 全屏计时器，环形进度条（SwiftUI Circle + trim）
- 显示：当前动作名、当前组数/总组数、倒计时、下一动作预览
- 已训练时间、预估剩余时间、整体进度
- 控制按钮（V1 仅 5 个）：暂停/继续、跳过、延长休息（+30 秒）、结束训练、语音模式切换
- 灵动岛/锁屏 Live Activity 控制（暂停/继续、跳过）
- 点状进度指示器（动作进度）
- 结束确认弹窗
- **训中编辑动作（加组/换动作）不在 V1 范围**

### 4.5 FeedbackView

- 训练统计：时长、完成率、完成动作数
- 疲劳程度选择：轻松/适中/吃力/疼痛
- 疼痛评分滑块（0–10，选择「吃力」或「疼痛」时显示）
- **若本次跳过 ≥ 1 个动作**：展示跳过动作列表 + 「调整健身档案」链接（跳转 HealthProfileView）
- **若疼痛评分 ≥ 6**：弹窗「是否将动作 X 加入禁忌？」，确认后写入 HealthProfile.contraindications
- 备注文本框（本地存储，不上 iCloud）
- 保存训练记录

### 4.6 HistoryView

- 两个 Tab：训练记录、我的模板
- 训练记录列表：完成百分比、疲劳表情、日期、时长
- 模板列表：一键加载
- 汇总统计：总训练次数、总时长、平均完成率

### 4.7 HealthProfileView（新增）

- 身体状态描述（多行文本，本地存储）
- 动作禁忌列表（chip 形式，可删除）
- 伤病史（多行文本，本地存储）
- 目标偏好（多选：减脂 / 增肌 / 康复 / 柔韧 / 心肺）
- 最后更新时间显示
- 「清空档案」按钮（需二次确认）

### 4.8 SettingsView

- AI 后端选择（Claude / OpenAI / **Mock**，默认 Mock）
- API Key 配置（通过 SecretsStore 写入 Keychain）
- 「我的健身档案」入口
- 语音偏好（语速、音调、VoiceMode 默认值）
- 关于与反馈

## 5. WorkoutEngine — 训练播放引擎

WorkoutEngine 是核心组件，将动作清单转化为可播放的训练流程。

### 5.1 状态机（已简化）

```
       ┌──────────────────────────────────┐
       │                                  │
       ▼                                  │
[idle] ──start──► [exercise] ──set done──► [rest] ┘
          │              │                   │
          │              │ last set          │ timeUp
          │              │ AND last exercise │
          │              ▼                   │
          │        [completed]               │
          │              ▲                   │
          │              │                   │
          └──────────────┘                   │
                                             │
                         next exercise's first set ▼
                                          [exercise]
```

**三种阶段（Phase）：**

- **exercise**：执行动作，倒计时 `duration` 秒
- **rest**：休息阶段。包含两种语义：
  - 同一动作的组间休息（使用 `restTime`）
  - 切换动作之间的休息（使用 `restTimeAfterLastSet`，由 PlanEditorView 全局设置或 AI 生成时指定，默认 20 秒）
- **completed**：训练完成

> 注：V1 不区分「过渡」和「组间休息」两种 UI 表现，统一以 rest 阶段呈现。UI 文案根据「下一动作是否同当前动作」切换：同动作显示「休息」，跨动作显示「准备下一个：X」。

### 5.2 状态属性

```swift
@Observable
class WorkoutEngine {
    // 当前状态
    var phase: Phase                  // .idle, .exercise, .rest, .completed
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

    // 依赖（构造注入）
    private let clock: Clock                  // 可注入，便于测试快进
    private let speech: SpeechService
    private let live: LiveActivityService
    private let resume: WorkoutResumeStore
    private let audio: AudioSessionController
}
```

### 5.3 关键方法

- `start(plan:)` — 加载动作清单并开始；激活 audio session；启动 Live Activity；写入 ResumeStore
- `pause()` / `resume()` — 暂停/继续；更新 Live Activity
- `skip()` — 跳过当前动作（直接进入下一个动作的第一组前的 rest）
- `extendRest(seconds: 30)` — 仅在 rest 阶段有效
- `endWorkout()` — 提前结束训练；结束 audio session 与 Live Activity；清除 ResumeStore

### 5.4 事件回调

```swift
func onPhaseChange(from: Phase, to: Phase)
func onExerciseStart(exercise: ExerciseItem, isFirstSet: Bool)
func onSetStart(exercise: ExerciseItem, setNumber: Int)
func onRestStart(nextExercise: ExerciseItem, isSameExercise: Bool)
func onCountdown(seconds: Int)       // 3, 2, 1
func onTenSecondWarning()            // 剩余 10 秒
func onWorkoutComplete()
```

### 5.5 时间估算

```
per exercise = (duration × sets) + (restTime × (sets - 1))
inter-exercise rest = restTimeAfterLastSet (默认 20s)
total = sum(per exercise) + restTimeAfterLastSet × (exerciseCount - 1)
```

### 5.6 计时器实现

WorkoutEngine 不直接使用 `Timer.scheduledTimer` 或 wall clock。改用注入的 `Clock` protocol：

```swift
protocol Clock {
    /// 异步等待指定秒数；可被取消
    func sleep(seconds: Int) async throws
    /// 当前单调时间（用于计算 elapsed）
    func now() -> ContinuousClock.Instant
}
```

- 生产实现 `SystemClock`：基于 `ContinuousClock.sleep(for:)`，不受 wall clock 调整影响
- 测试实现 `MockClock`：手动 advance，支持瞬时快进数小时

WorkoutEngine 的 tick 循环用 `Task { while !cancelled { try await clock.sleep(seconds: 1); tick() } }` 实现，暂停时取消 Task，恢复时重新创建。

## 6. AI Service 可插拔架构

### 6.1 Protocol（已修改：支持多轮对话）

```swift
struct ChatMessage: Codable {
    enum Role: String, Codable { case system, user, assistant }
    let role: Role
    let content: String
}

struct PlanGenerationContext {
    let healthProfile: HealthProfileSnapshot     // 见 §9.5
    let availableExercises: [ExerciseTemplate]   // ExerciseLibrary 的快照
    let preferredLanguage: String                // "zh-CN"
}

protocol AIService {
    /// 多轮对话生成。传入完整历史 + system context，返回 assistant 的下一条消息（可能含 plan JSON）。
    func generatePlan(
        messages: [ChatMessage],
        context: PlanGenerationContext
    ) async throws -> AIResponse
}

struct AIResponse {
    let assistantMessage: String       // 展示给用户的回复文本
    let plan: AIGeneratedPlan?         // 若 AI 生成了新计划则非 nil
}
```

### 6.2 实现类

- **ClaudeProvider**：调用 Anthropic Claude API（推荐 claude-sonnet-4-6 或更新）
- **OpenAIProvider**：调用 OpenAI Responses/Chat Completions API
- **MockProvider**：本地规则引擎，默认 provider，开发/预览/降级用

### 6.3 Prompt 策略（已重写：查表模式）

**AI 输出 schema 严格限制为查表模式**，不允许 AI 自创动作：

```jsonc
{
  "assistant_message": "已为你生成一份 15 分钟的低冲击训练...",
  "plan": {
    "name": "膝盖友好下肢训练",
    "exercises": [
      { "templateId": "chair_squat", "sets": 3, "duration": 30, "restTime": 30, "order": 0 },
      { "templateId": "bed_glute_bridge", "sets": 3, "duration": 40, "restTime": 30, "order": 1 }
    ],
    "rest_time_after_last_set": 20
  }
}
```

- `templateId` 必须存在于 ExerciseLibrary，否则该条目剔除并 log
- 客户端解析后从 ExerciseLibrary 查表填充 `name / instructions / safety / difficulty / categories`
- `assistant_message` 直接展示给用户
- 若 AI 仅返回闲聊（如「你能告诉我更多关于你的伤情吗？」），`plan` 字段为 null

**System prompt 模板（伪代码）**：

```
你是一名健身教练 AI。
- 用户健身档案：{healthProfile.serialize()}
- 可用动作库（仅能选择以下 id）：{availableExercises.map { id, name, categories }}
- 输出必须是合法 JSON，schema 如上。
- 若用户问题需要澄清，先提问，plan 字段留空。
```

### 6.4 降级策略

AI API 调用失败（网络/配额/Key 无效/超时）时，自动降级到 MockProvider 并在 UI 提示。MockProvider 实现一套简化规则（基于关键词匹配 + 档案禁忌过滤 + 时间预算），保证用户始终能生成计划。

### 6.5 SecretsStore（新增）

API Key 通过 Keychain 存储，不进入 SwiftData，不上 iCloud。

```swift
enum AIProviderID: String { case claude, openai }

protocol SecretsStore {
    func get(provider: AIProviderID) -> String?
    func set(provider: AIProviderID, key: String) throws
    func clear(provider: AIProviderID) throws
}

final class KeychainSecretsStore: SecretsStore {
    // kSecClass = kSecClassGenericPassword
    // kSecAttrAccessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    // kSecAttrService = "ai-timer.api-key"
    // kSecAttrAccount = provider.rawValue
    // 不参与 iCloud Keychain 同步（不设 kSecAttrSynchronizable）
}
```

## 7. SpeechService 语音播报

### 7.1 VoiceMode

```swift
enum VoiceMode {
    case off        // 静音（仍会有静音音频保活，见 §8.1）
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
| 休息开始（同动作） | "休息 N 秒" |
| 休息开始（切换动作） | "休息 N 秒，下一个：[动作名]" + 可选 instructions（VoiceMode = .rest 时） |
| 训练完成 | "训练完成！辛苦了，记得拉伸" |

### 7.3 动作要领播报逻辑

- `VoiceMode.first`：每个动作的第一组开始前，播报该动作的 instructions
- `VoiceMode.every`：每组开始前都播报 instructions
- `VoiceMode.rest`：组间休息或动作切换 rest 期间，播报下一个动作的 instructions
- `VoiceMode.safety`：动作开始前播报 safety 安全提醒

### 7.4 实现

使用 AVSpeechSynthesizer，配置 zh-CN 语言，语速略慢（`rate: 0.9`），音调略高（`pitch: 1.05`）。SpeechService 与 AudioSessionController 协作，确保 audio session 已 active 才开始播报。

## 8. 后台运行与灵动岛

### 8.1 后台音频与保活（已重写）

iOS 真正能让 App 在锁屏/后台持续运行的唯一可靠方式是 **Background Modes (audio) + AVAudioSession.active + 持续有音频在播放**。`performExpiringActivity` 仅能维持几十秒，`BGProcessingTask` 由系统调度运行时机，**两者都不能用来跑实时计时器**——V1 之前文档的描述是错误的。

**实现方案**：

- **AudioSessionController**：训练开始时配置并激活 audio session

  ```swift
  let session = AVAudioSession.sharedInstance()
  try session.setCategory(.playback, mode: .spokenAudio, options: .mixWithOthers)
  try session.setActive(true)
  ```

  - 选择 `.mixWithOthers`：训练时不打断用户的背景音乐/播客
  - **已知 trade-off**：播报「还剩 10 秒」可能被背景音乐盖住。Settings 中提示用户「如听不清播报，请调高媒体音量或关闭背景音乐」。V2 可考虑增加「自动 ducking」开关切换 `.duckOthers`

- **Background Modes**：在 Info.plist 中声明 `audio` 后台模式

- **SilentAudioKeepalive**：当 VoiceMode = .off **且** 当前没有 speech 在播报时，循环播放一段 1 秒、零音量的静音音频文件（无损 PCM 或 m4a，bundle 内置）。`AVAudioPlayer.numberOfLoops = -1`。
  - 启动时机：`engine.start(plan:)` 完成时
  - 停止时机：`engine.endWorkout()` 或训练完成
  - 与 speech 协作：speech 开始播报时不需要停止静音音频（mixWithOthers 共存）；选择 .first/.every 等模式时 speech 已经在持续打断静音，无需 Keepalive，但留着也无害——简化逻辑统一启用

- **生命周期处理**：
  - 进入后台：保持 WorkoutEngine 运行，audio session 维持 active
  - 返回前台：同步 UI 与引擎状态
  - 来电/系统中断：监听 `AVAudioSession.interruptionNotification`，收到 `.began` 自动暂停训练并更新 Live Activity；收到 `.ended` **不自动恢复**，由用户手动点击「继续」（避免来电意外结束后立刻继续训练，用户没准备好）
  - 内存警告/系统终止：在 scenePhase 变化时持久化当前训练状态到 WorkoutResumeStore（见 §12.2）

### 8.2 Live Activity & 灵动岛（已重写：事件驱动）

**关键修正：不每秒调用 `Activity.update()`**。ActivityKit 有未公开的更新预算，每秒调用持续几分钟会被系统节流到 1–2 分钟才更新一次，倒计时会失效。

**标准做法**：

1. ContentState 存「当前阶段结束的绝对时间戳」而非 `timeRemaining`
2. Widget UI 使用 `Text(timerInterval: ...range, countsDown: true)`——**系统在 Live Activity 内自动每秒重绘**，不消耗 update 预算
3. `Activity.update()` **仅在状态变化时调用**：阶段切换、暂停/继续、组数变化、训练结束

**ContentState**：

```swift
struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: Phase                  // .exercise, .rest
        var exerciseName: String
        var currentSet: Int
        var totalSets: Int
        var phaseStart: Date              // 阶段开始绝对时间
        var phaseEnd: Date                // 阶段结束绝对时间（用于 Text(timerInterval:)）
        var isRunning: Bool
        var pausedRemaining: Int?         // 暂停时记录剩余秒数；恢复时基于此重算 phaseEnd
        var nextExerciseName: String?
        var nextExerciseIsDifferent: Bool // 休息阶段用：是否切换动作
    }
    var planName: String
}
```

**显示内容**：

| 状态 | 灵动岛（紧凑） | 灵动岛（展开） | 锁屏 Live Activity |
|------|---------------|---------------|-------------------|
| 运动中 | 动作名（缩写） + 倒计时 | 动作名、组数、环形进度、倒计时、下一动作 | 完整 |
| 休息中（同动作） | "休息" + 倒计时 | 休息倒计时、控制按钮 | 完整 |
| 休息中（切动作） | "准备" + 倒计时 | 下一动作名 + 倒计时 + 控制按钮 | 完整 |
| 暂停 | 动作名 + "已暂停" | 暂停状态、继续按钮 | 完整 |

控制按钮（锁屏和灵动岛展开态）：暂停/继续、跳过当前动作。

**LiveActivityService**：

```swift
@Observable
final class LiveActivityService {
    var currentActivity: Activity<WorkoutAttributes>?

    func start(plan: WorkoutPlan, initialState: WorkoutAttributes.ContentState)
    func update(state: WorkoutAttributes.ContentState)   // 仅事件驱动
    func end()                                            // 训练结束时关闭
}
```

**WorkoutEngine 集成**：仅在以下时机调用 `update`：

- `onPhaseChange` → 更新 phase、phaseStart、phaseEnd
- `onSetStart` → 更新 currentSet
- `pause()` / `resume()` → 更新 isRunning、pausedRemaining、phaseEnd（恢复时基于 pausedRemaining 重算）
- `endWorkout()` / `onWorkoutComplete()` → 调用 `end()`

灵动岛交互通过 AppIntent 处理按钮点击事件，回调到 WorkoutEngine 执行暂停/跳过操作。

## 9. 数据模型

> **iCloud 同步策略**：除明确标注「仅本地」的字段外，所有 @Model 通过 CloudKit-backed ModelContainer 同步。
> **SwiftData + CloudKit 约束**：所有属性必须有默认值或 optional，所有 to-many 关系必须 optional 且通过 `@Relationship` 显式声明。本节代码示例已遵守该约束。

### 9.1 WorkoutPlan

```swift
@Model
final class WorkoutPlan {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseItem]? = []
    var createdAt: Date = Date()
    var source: PlanSource = PlanSource.aiGenerated
    // 仅本地：userContext 包含用户身体信息描述，不上 iCloud
    // 实现方案：拆分到独立的 PlanLocalMetadata 模型，使用本地 ModelContainer
    var localMetadataID: UUID?
    var restTimeAfterLastSet: Int = 20
}

/// 本地存储（不参与 CloudKit 容器）
@Model
final class PlanLocalMetadata {
    var planID: UUID = UUID()
    var userContext: String = ""
}
```

### 9.2 ExerciseItem

```swift
@Model
final class ExerciseItem {
    var id: UUID = UUID()
    var templateId: String = ""        // 对应 ExerciseLibrary 中的模板
    var name: String = ""
    var duration: Int = 30             // 每组秒数
    var sets: Int = 3
    var restTime: Int = 30             // 组间休息秒数
    var instructions: String = ""      // 从 ExerciseLibrary 查表填充
    var safety: String = ""            // 从 ExerciseLibrary 查表填充
    var difficulty: Difficulty = Difficulty.easy
    var order: Int = 0
}
```

### 9.3 WorkoutSession

```swift
@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var plan: WorkoutPlan?
    var completedExerciseIds: [String] = []
    var skippedExerciseIds: [String] = []
    var totalSeconds: Int = 0
    var feeling: Feeling = Feeling.easy
    var painScore: Int = 0
    // 仅本地：notes 可能包含身体描述，不上 iCloud
    var localMetadataID: UUID?
}

@Model
final class SessionLocalMetadata {
    var sessionID: UUID = UUID()
    var notes: String = ""
}
```

### 9.4 WorkoutTemplate

```swift
@Model
final class WorkoutTemplate {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseItem]? = []
    var createdAt: Date = Date()
}
```

### 9.5 HealthProfile（新增，仅本地存储）

```swift
@Model
final class HealthProfile {
    var id: UUID = HealthProfile.singletonID       // 单例 sentinel（全零 UUID）
    var bodyStatusDescription: String = ""         // 用户自述
    var contraindications: [String] = []           // 禁忌动作的 templateId 列表
    var dislikedExercises: [String] = []           // 不喜欢的 templateId（来自 PlanEditorView 标记不适）
    var injuryHistory: String = ""                 // 伤病史
    var goalPreferences: [String] = []             // ["减脂", "康复", ...]
    var updatedAt: Date = Date()

    static let singletonID = UUID(uuid: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
}

/// 注入 AI prompt 的精简快照
struct HealthProfileSnapshot: Codable {
    let bodyStatus: String
    let contraindicationIDs: [String]
    let dislikedIDs: [String]
    let injuryHistory: String
    let goals: [String]
}
```

`HealthProfileStore` 提供 `current() -> HealthProfile` 与 `snapshot() -> HealthProfileSnapshot`，后者用于 AI prompt 注入。

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

enum Phase: String, Codable {
    case idle
    case exercise
    case rest
    case completed
}
```

## 11. ExerciseLibrary 内置动作库

内置 16+ 个动作模板（V1 闭集，**不支持用户添加自定义动作**）。每个模板包含：

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

动作库以静态资源形式打包（JSON 文件 + Swift 强类型加载层），供 AI 选取（仅返回 templateId）和 MockProvider 降级使用。

## 12. 错误处理与恢复

### 12.1 错误场景表

| 场景 | 处理方式 |
|------|---------|
| AI API 调用失败 | 降级到 MockProvider，显示提示 toast |
| 网络不可用 | 使用 MockProvider，提示离线模式 |
| API Key 未配置且 provider 非 Mock | 引导用户前往 SettingsView 配置 |
| 语音合成不可用 | 静默降级，仅视觉提示 |
| 训练中 App 进入后台 | 保持计时器和语音运行，Live Activity 持续更新 |
| 训练中 App 被系统终止 | 持久化训练状态到 WorkoutResumeStore，下次启动恢复（见 §12.2） |
| 训练中来电/中断 | 自动暂停训练，中断结束后**不自动恢复**，由用户手动继续 |
| Live Activity 不可用（旧机型/系统设置关闭） | 静默降级，仅使用通知和后台音频 |
| AI 返回非法 templateId | 剔除该条目并 log，其余动作正常使用 |
| AI 返回非法 JSON | 提示「AI 输出异常，请重试」，保留当前对话 |

### 12.2 训练状态恢复机制（新增）

**WorkoutResumeStore**：

```swift
struct ResumeSnapshot: Codable {
    let planID: UUID
    let exerciseIndex: Int
    let currentSet: Int
    let phase: Phase
    let phaseRemainingSeconds: Int
    let completedIDs: [String]
    let skippedIDs: [String]
    let totalElapsed: Int
    let savedAt: Date
}

protocol WorkoutResumeStore {
    func save(_ snapshot: ResumeSnapshot)
    func load() -> ResumeSnapshot?
    func clear()
}
```

- WorkoutEngine 每次 phase 切换或暂停时写入 snapshot
- HomeView 在 onAppear / scenePhase = .active 时调用 `load()`，如果存在 snapshot：
  - 若 `Date().timeIntervalSince(savedAt) > 30 * 60`：直接 clear（超时丢弃）
  - 若 PlanRepository 中已找不到 `planID` 对应的 plan（用户已删除或 iCloud 同步未到位）：clear 并 toast「无法恢复，原始训练计划已不存在」
  - 否则弹窗「你有 N 分钟前未完成的训练，是否恢复？」
    - 「恢复」→ 跳转 WorkoutPlayerView，调用 `engine.resume(from: snapshot)`
    - 「放弃」→ clear
- `engine.endWorkout()` 与 `onWorkoutComplete()` 都会调用 clear

实现可选用 UserDefaults 存 JSON（轻量）或独立的 SwiftData 模型（本地容器）。

## 13. 非功能需求

- **性能**：计时器精度 ±0.1 秒，不因 UI 更新而漂移；使用 `ContinuousClock` 不受 wall clock 调整影响
- **后台**：支持后台音频模式，训练中锁屏仍可接收语音播报和 Live Activity 更新；VoiceMode.off 时通过静音音频保活
- **灵动岛**：iPhone 14 Pro 及以上支持灵动岛实时显示，旧机型支持锁屏 Live Activity；不可用时静默降级
- **无障碍**：VoiceOver 支持，动态字体
- **国际化**：首版中文，架构预留多语言（AI prompt 通过 `PlanGenerationContext.preferredLanguage` 传递）
- **隐私**：API Key 仅存 Keychain；用户身体描述、训练备注仅本地，不上 iCloud；AI 调用前在 UI 提示「将向 [Claude/OpenAI] 发送你的健康描述」
- **最低版本**：iOS 17+

## 14. 测试策略（新增）

### 14.1 单元测试（必须）

**WorkoutEngine**（核心，要求 ≥80% 行覆盖）：

- 完整状态转移：idle → exercise(set 1) → rest → exercise(set 2) → ... → completed
- 跨动作切换：最后一组结束 → rest(切动作) → 下一动作 first set
- 暂停/恢复：暂停后 timeRemaining 不变，恢复后继续计时
- 跳过：当前动作直接结束，进入下一动作的 rest
- 延长休息：仅 rest 阶段有效，其他阶段调用是 no-op
- 来电中断：模拟 `AVAudioSessionInterruption.began` → 引擎进入暂停状态
- 时间估算：start 时计算的 estimatedRemaining 与实际播放完成的 totalElapsed 相等（误差 ≤1 秒）

通过注入 `MockClock` 实现快进，测试运行时间可控制在毫秒级。

**AIService 实现**：

- MockProvider：端到端测试（输入用户描述，验证输出 plan 符合 schema 且只引用合法 templateId）
- ClaudeProvider / OpenAIProvider：用 `URLProtocol` stub 网络层，测试请求构造、响应解析、错误降级
- 非法 templateId 剔除逻辑
- 非法 JSON 错误处理

**PlanRepository / HealthProfileStore**：

- SwiftData in-memory container 测试 CRUD
- HealthProfileSnapshot 序列化正确性

**SecretsStore**：

- 真实 Keychain（test target entitlement）或 mock 实现的接口契约测试

### 14.2 UI / 集成测试

1 个 XCUITest 关键路径：

- 首次启动 → SettingsView 配置 API Key（mock 路径，使用 Mock provider 跳过）→ ChatPlanView 输入描述 → 等待 plan 生成 → 进入 PlanEditorView → 开始训练 → 跳过一个动作 → 结束训练 → FeedbackView 填写疼痛评分 → 保存 → HistoryView 验证记录

### 14.3 不强求自动测试的部分

- LiveActivityService（依赖 ActivityKit，需真机+锁屏验证）
- SpeechService 音频输出（人耳验证）
- 后台音频实际保活效果（真机锁屏 30 分钟验证）

这些部分通过手工验证清单覆盖，清单文档化在 `docs/manual-verification-checklist.md`（实施时创建）。

## 附录 A. V2 关键决策记录

| # | 主题 | V1 现状 | V2 决策 |
|---|------|---------|---------|
| 1 | ChatPlanView 形态 | 文档说"聊天界面"但 protocol 单次调用 | 多轮对话 + 快捷标签预填，protocol 改 messages |
| 2 | WorkoutEngine 状态机 | 含 transition 阶段但回调/播报不全 | 去掉 transition，统一为 rest |
| 3 | 后台保活 | 误用 performExpiringActivity / BGProcessingTask | 改为 audio mode + 静音音频保活 |
| 4 | AVAudioSession options | .mixWithOthers | 保留 .mixWithOthers，明确 trade-off |
| 5 | Live Activity 更新 | 每秒 update | 事件驱动 + Text(timerInterval:) |
| 6 | API Key 存储 | 未明确 | 新增 SecretsStore（Keychain） |
| 7 | iCloud 同步范围 | 全量上 iCloud | 排除 userContext / notes |
| 8 | 训练中断恢复 | 仅写"持久化恢复" | HomeView 弹窗 + 30 分钟超时；来电不自动恢复 |
| 9 | AI 输出范围 | 模糊 | 查表模式，AI 仅返回 templateId + 参数 |
| 10 | 不适信号闭环 | 缺失 | 新增 HealthProfile + 各页面写入路径 |
| 11 | 训中编辑 | 未明确 | V1 不支持 |
| 12 | 测试策略 | 缺失 | 核心覆盖 + Clock 可注入 + 1 个 XCUITest |
| 13 | ExerciseLibrary 扩展 | 未明确 | V1 闭集，不支持用户添加 |
| 14 | 默认 provider | 未明确 | 默认 Mock，免配置可体验 |
