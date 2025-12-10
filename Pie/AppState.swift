import SwiftUI
import Combine

class AppState: ObservableObject {
    // 0 = Pantry, 1 = Split
    @Published var selectedTab: Int = 1
    
    // Navigation Path for the Pantry Tab
    @Published var pantryPath = NavigationPath()
    
    // Helper to perform the navigation
    func navigateToPantry(with bill: Bill) {
        // 1. Switch Tab
        selectedTab = 0
        
        // 2. Reset path (optional, if you want a clean stack) or just append
        // We append after a brief delay to ensure the tab switch registers
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.pantryPath.append(bill)
        }
    }
}
