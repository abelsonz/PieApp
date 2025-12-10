import SwiftUI
import SwiftData

@main
struct PieApp: App {
    // Check if user has seen onboarding
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    // Create the central Navigation State
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(appState) // Inject here
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: Bill.self)
    }
}
