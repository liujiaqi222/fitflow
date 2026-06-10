import Foundation

enum AppRoute: Hashable {
    case chat
    case editor(UUID)
    case workout(UUID)
    case feedback(UUID)
    case history
    case healthProfile
    case settings
}
