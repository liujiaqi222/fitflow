import SwiftUI

// MARK: - Prototype Entry Point
//
// Card-centered UI with 3 tabs: 训练 / 历史 / 我的
// AI 对话 is a sub-page (NavigationLink push from 训练 tab)
// Flow: Home → [开始训练] → WorkoutPlayer → Feedback
//       Home → [定制训练] → Chat → [使用此计划] → PlanEditor → WorkoutPlayer → Feedback

struct PrototypeHomeView: View {
    var body: some View {
        VariantAHome()
    }
}

#Preview {
    PrototypeHomeView()
}
