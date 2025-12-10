import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            Color.pieCream.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo / Icon
                Image(systemName: "circle.circle.fill") // Replace with Image("AppIcon") if available
                    .font(.system(size: 80))
                    .foregroundColor(.pieCrust)
                    .shadow(color: .pieCrust.opacity(0.3), radius: 20)
                
                Text("Welcome to Pie")
                    .pieFont(.largeTitle, weight: .heavy)
                    .foregroundColor(.pieCoffee)
                
                Text("Splitting bills doesn't have to be awkward.\nScan, tap, and share fairly.")
                    .pieFont(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(0.7)
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }) {
                    Text("Let's Eat")
                        .pieFont(.headline, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pieCrust)
                        .cornerRadius(30)
                        .shadow(color: .pieCrust.opacity(0.4), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}
