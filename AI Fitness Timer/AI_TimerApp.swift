import SwiftUI

@main
struct AI_TimerApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            PrototypeHomeView()
            #else
            HomeView()
            #endif
        }
    }
}
