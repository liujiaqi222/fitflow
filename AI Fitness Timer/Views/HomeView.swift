import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("AI Fitness Timer")
                        .font(.title2.weight(.semibold))
                    Text("Mock provider ready")
                        .foregroundStyle(.secondary)
                }

                Section("可见进展") {
                    NavigationLink("打开计时器预览") {
                        WorkoutEngineCheckpointView()
                    }
                }
            }
            .navigationTitle("训练")
        }
    }
}
