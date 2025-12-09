import SwiftUI
import SwiftData

struct PantryView: View {
    @Query(sort: \Bill.date, order: .reverse) var recentBills: [Bill]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pieCream.ignoresSafeArea()
                
                if recentBills.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "basket")
                            .font(.system(size: 50))
                            .foregroundColor(.pieCoffee.opacity(0.3))
                        Text("The Pantry is Empty")
                            .pieFont(.title3, weight: .bold)
                            .foregroundColor(.pieCoffee)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(recentBills) { bill in
                                // Navigation Link to see details could go here
                                HStack {
                                    // Icon
                                    Circle()
                                        .stroke(Color.pieCrust, lineWidth: 3)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text(bill.title.prefix(1))
                                                .pieFont(.headline, weight: .bold)
                                                .foregroundColor(.pieCrust)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(bill.title)
                                            .pieFont(.headline, weight: .bold)
                                        Text(bill.date.formatted(date: .abbreviated, time: .shortened))
                                            .pieFont(.caption)
                                            .opacity(0.6)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(String(format: "$%.2f", bill.totalAmount))
                                        .pieFont(.headline, weight: .bold)
                                        .foregroundColor(.pieCoffee)
                                }
                                .padding()
                                .background(Color.white) // Clean White
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Pantry")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}