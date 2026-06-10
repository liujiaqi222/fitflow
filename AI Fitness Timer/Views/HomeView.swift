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
            }
            .navigationTitle("训练")
        }
    }
}
