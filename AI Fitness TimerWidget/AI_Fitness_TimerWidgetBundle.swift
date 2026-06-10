import SwiftUI
import WidgetKit

struct AI_Fitness_TimerWidgetEntry: TimelineEntry {
    let date: Date
}

struct AI_Fitness_TimerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AI_Fitness_TimerWidgetEntry {
        AI_Fitness_TimerWidgetEntry(date: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (AI_Fitness_TimerWidgetEntry) -> Void
    ) {
        completion(AI_Fitness_TimerWidgetEntry(date: Date()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<AI_Fitness_TimerWidgetEntry>) -> Void
    ) {
        completion(Timeline(entries: [AI_Fitness_TimerWidgetEntry(date: Date())], policy: .never))
    }
}

struct AI_Fitness_TimerWidgetView: View {
    var entry: AI_Fitness_TimerWidgetEntry

    var body: some View {
        Text("AI Fitness Timer")
    }
}

struct AI_Fitness_TimerWidget: Widget {
    let kind = "AI_Fitness_TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AI_Fitness_TimerWidgetProvider()) { entry in
            AI_Fitness_TimerWidgetView(entry: entry)
        }
        .configurationDisplayName("AI Fitness Timer")
        .description("Fitness timer status.")
    }
}

@main
struct AI_Fitness_TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        AI_Fitness_TimerWidget()
    }
}
