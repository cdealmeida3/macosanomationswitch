import SwiftUI

@main
struct AnimationSwitchApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuView(model: model)
        } label: {
            // The icon shows the state (plan Q13): sparkles while animations
            // are on, a bolt while they are off and everything is instant.
            Image(systemName: model.animationsDisabled ? "bolt.fill" : "sparkles")
                .accessibilityLabel(model.animationsDisabled ? "Animation Switch: animations off" : "Animation Switch: animations on")
        }
        .menuBarExtraStyle(.window)
    }
}
