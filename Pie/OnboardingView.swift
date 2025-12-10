import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @Environment(\.dismiss) var dismiss // Allow it to be dismissed if shown as a sheet
    
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color.pieCream.ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    OnboardingPage(
                        imageName: "circle.circle.fill",
                        title: "Welcome to Pie",
                        description: "Splitting bills doesn't have to be awkward.\nScan, tap, and share fairly."
                    )
                    .tag(0)
                    
                    // Page 2: Rename Logic
                    OnboardingPage(
                        imageName: "pencil.circle.fill",
                        title: "Rename Anyone",
                        description: "Long-press on any diner avatar to change their name or color."
                    )
                    .tag(1)
                    
                    // Page 3: Sharing
                    OnboardingPage(
                        imageName: "square.and.arrow.up.circle.fill",
                        title: "Share the Slice",
                        description: "Tap the share icon on the receipt details page to send a visual breakdown."
                    )
                    .tag(2)
                    
                    // Page 4: Pantry Management
                    OnboardingPage(
                        imageName: "trash.circle.fill",
                        title: "Clean the Pantry",
                        description: "Swipe left on any saved receipt in the Pantry to delete it."
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                // FIX: Changed from .always to .never to remove the black pill background
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .onAppear {
                    // Set the dot colors to match your brand
                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.pieCrust)
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.pieCoffee.opacity(0.2))
                }
                
                // Button Logic
                Button(action: {
                    if currentPage < 3 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    Text(currentPage < 3 ? "Next" : "Let's Eat")
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
    
    func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
            dismiss()
        }
    }
}

// Helper Subview for Pages
struct OnboardingPage: View {
    let imageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundColor(.pieCrust)
                .shadow(color: .pieCrust.opacity(0.3), radius: 20)
            
            Text(title)
                .pieFont(.largeTitle, weight: .heavy)
                .foregroundColor(.pieCoffee)
            
            Text(description)
                .pieFont(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(0.7)
            
            Spacer()
        }
    }
}
