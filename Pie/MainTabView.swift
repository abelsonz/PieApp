import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var appState: AppState // Access global state
    
    init() {
        // Hides the standard system tab bar so we can use our custom floating one
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Content
            TabView(selection: $appState.selectedTab) { // Bind to AppState
                PantryView()
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)
                
                SplitView()
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)
            }
            
            // Custom Floating Tab Bar
            HStack {
                // Tab 1: Pantry
                Button(action: { appState.selectedTab = 0 }) {
                    VStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 26))
                        Text("Pantry")
                            .pieFont(.subheadline, weight: .bold)
                    }
                    .foregroundColor(appState.selectedTab == 0 ? .pieCrust : .pieCoffee.opacity(0.4))
                    .frame(maxWidth: .infinity)
                }
                
                // Divider
                Rectangle()
                    .fill(Color.pieCoffee.opacity(0.1))
                    .frame(width: 1, height: 35)
                
                // Tab 2: Split
                Button(action: { appState.selectedTab = 1 }) {
                    VStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 26))
                        Text("Split")
                            .pieFont(.subheadline, weight: .bold)
                    }
                    .foregroundColor(appState.selectedTab == 1 ? .pieCrust : .pieCoffee.opacity(0.4))
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(Color.pieCream)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
