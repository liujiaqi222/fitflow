# Handoff — AI Fitness Timer 设计阶段交接

> 创建时间：2026-06-10
> 上一阶段：brainstorming（已完成）
> 下一阶段：writing-plans（待执行）

## 给下一个 agent 的指令

你接手的是一个 iOS 健身计时 App 的设计 → 实施过渡。**brainstorming 阶段已完成，spec 已写好并经用户审阅批准。** 你的任务是直接进入 `superpowers:writing-plans` skill，把 spec 拆成可执行的实施计划。

**不要重新做 brainstorming。不要重新征求设计决策。** 用户已经明确批准了 spec。

## 关键文件

| 路径 | 说明 |
|------|------|
| `docs/superpowers/specs/2026-06-10-ai-fitness-timer-design.md` | **已批准的 V2 设计文档**，writing-plans 的唯一输入 |
| `docs/AI Fitness Timer — 设计文档.md` | V1 原始文档，已被 V2 取代，**只作为对照参考，不要按它实施** |

## 当前项目状态

- 仓库：`/Users/liujiaqi/code/ai-timer`
- 分支：`main`
- 最近 commit：`7156a92 docs: 新增 AI Fitness Timer V2 打磨版设计文档`
- 工作树干净
- **尚未有任何代码**——Swift 项目本身还没有 scaffold

## brainstorming 阶段已做出的 14 项关键决策

详见 V2 spec 附录 A。要点：

1. ChatPlanView 多轮对话 + 快捷标签预填
2. WorkoutEngine 状态机简化（去掉 transition，统一为 rest）
3. 后台保活用 audio mode + 静音音频 keepalive（**不要**用 performExpiringActivity / BGProcessingTask）
4. AVAudioSession 用 `.mixWithOthers`
5. Live Activity 事件驱动 + `Text(timerInterval:)`（**不要**每秒 update）
6. SecretsStore 用 Keychain，`WhenUnlockedThisDeviceOnly`
7. iCloud 同步排除 `userContext` / `notes` 敏感字段（拆 LocalMetadata 模型）
8. 中断恢复：HomeView 弹窗 + 30 分钟超时 + 来电不自动恢复
9. AI 查表模式（只返回 templateId + 参数，instructions/safety 从本地库查）
10. 新增 HealthProfile 模型形成不适信号闭环
11. V1 不支持训中编辑动作
12. 测试策略：Clock 可注入 + WorkoutEngine 核心覆盖 + 1 个 XCUITest
13. ExerciseLibrary V1 闭集，不可扩展
14. 默认 AI provider = Mock（免配置即可体验）

## writing-plans 阶段的建议

由于这是一个**完全空白的仓库**（除了 docs），实施计划需要从项目脚手架开始。建议任务大致顺序：

1. **脚手架**：Xcode 项目（SwiftUI App template, iOS 17+），Bundle ID, 目录结构，SPM 配置
2. **基础设施层**：`Clock` protocol + SystemClock + MockClock；`SecretsStore` + KeychainSecretsStore；`AudioSessionController`
3. **数据层**：所有 @Model + SwiftData/CloudKit 两个 ModelContainer（云 + 本地拆分）；ExerciseLibrary 资源加载；PlanRepository / HealthProfileStore / WorkoutResumeStore
4. **AI 层**：AIService protocol、ChatMessage / AIResponse 等数据类型；MockProvider（先做）；ClaudeProvider / OpenAIProvider（依赖 URLProtocol stub 可测）；降级机制
5. **WorkoutEngine**：状态机 + tick 循环 + 事件回调 + ResumeStore 集成；完整单元测试（用 MockClock）
6. **语音 & 后台**：SpeechService；SilentAudioKeepalive；AVAudioSessionInterruption 处理
7. **Live Activity**：WorkoutAttributes、Widget extension、AppIntent 控制按钮、LiveActivityService 事件驱动 update
8. **UI 层**（按依赖顺序）：SettingsView → HealthProfileView → HomeView → ChatPlanView → PlanEditorView → WorkoutPlayerView → FeedbackView → HistoryView
9. **集成 & 验证**：XCUITest 关键路径 + 手工验证清单 `docs/manual-verification-checklist.md`

每个任务都应该独立可测、独立可验证，符合 writing-plans skill 的「review checkpoint」要求。

## 用户给出的指令原文

> "我同意，但是 context window 不够了，需要 handoff 到下一个 agent 了"

即：**用户已批准 spec**，因 context 限制需要换 agent 继续，下一步是 writing-plans。

## 给下一个 agent 的第一步

1. 读 `docs/superpowers/specs/2026-06-10-ai-fitness-timer-design.md` 全文
2. 调用 `Skill` tool 启动 `superpowers:writing-plans`
3. 按照该 skill 的流程，把 spec 拆成实施计划，写到 `docs/superpowers/plans/2026-06-10-ai-fitness-timer-plan.md`（或 skill 指定的位置）
4. 完成后提交 git
