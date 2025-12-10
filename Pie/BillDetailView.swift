import SwiftUI

struct BillDetailView: View {
    @Environment(\.dismiss) var dismiss
    let bill: Bill
    
    // For Screenshot
    @State private var renderedImage: Image?
    
    var billSubtotal: Double {
        bill.items.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        ZStack {
            Color.pieCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .foregroundColor(.pieCoffee)
                            .padding(12)
                            .background(Color.white.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Receipt Details")
                        .pieFont(.headline, weight: .bold)
                        .foregroundColor(.pieCoffee.opacity(0.7))
                    Spacer()
                    
                    // Share Button
                    if let renderedImage = renderedImage {
                        ShareLink(item: renderedImage, preview: SharePreview("Receipt for \(bill.title)", image: renderedImage)) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body)
                                .foregroundColor(.pieCoffee)
                                .padding(12)
                                .background(Color.white.opacity(0.5))
                                .clipShape(Circle())
                        }
                    } else {
                        // Placeholder
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .foregroundColor(.pieCoffee.opacity(0.3))
                            .padding(12)
                            .background(Color.white.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)
                .padding(.bottom, 10)
                
                // Content
                ScrollView {
                    contentToShare
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar) // <--- HIDES THE TAB BAR
        .gesture(DragGesture().onEnded { value in
            if value.translation.width > 60 { dismiss() }
        })
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                renderImage()
            }
        }
    }
    
    // Extracted view for both display and screenshot
    var contentToShare: some View {
        VStack(spacing: 25) {
            // 1. The "Ticket" (Grand Total)
            VStack(spacing: 5) {
                Text(bill.title)
                    .pieFont(.body, weight: .semibold)
                    .opacity(0.6)
                
                Text(String(format: "$%.2f", bill.totalAmount))
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(.pieCrust)
                
                HStack(spacing: 15) {
                    Label(String(format: "Tax $%.2f", bill.taxAmount), systemImage: "building.columns")
                    Label(String(format: "Tip $%.2f", bill.tipAmount), systemImage: "star.fill")
                }
                .font(.caption)
                .foregroundColor(.pieCoffee)
                .opacity(0.5)
                .padding(.top, 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            
            // 2. The Breakdown
            VStack(alignment: .leading, spacing: 15) {
                Text("Split Breakdown")
                    .pieFont(.title3, weight: .bold)
                    .foregroundColor(.pieCoffee)
                    .padding(.horizontal)
                
                if bill.diners.isEmpty {
                    Text("No diner details available.")
                        .pieFont(.body)
                        .opacity(0.5)
                        .padding(.horizontal)
                } else {
                    ForEach(bill.diners) { diner in
                        DinerSummaryCard(diner: diner, bill: bill, billSubtotal: billSubtotal)
                            .padding(.horizontal)
                    }
                }
            }
            
            // Branding Footer
            Text("Split with Pie")
                .pieFont(.caption, weight: .bold)
                .foregroundColor(.pieCrust)
                .padding(.top, 20)
        }
        .padding(20)
        .background(Color.pieCream)
    }
    
    @MainActor
    func renderImage() {
        let renderer = ImageRenderer(content: contentToShare.frame(width: 375))
        renderer.scale = 3.0
        
        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
        }
    }
}

struct DinerSummaryCard: View {
    let diner: Diner; let bill: Bill; let billSubtotal: Double
    
    var dinerItems: [BillItem] { bill.items.filter { $0.assignedDinerIds.contains(diner.id) } }
    
    var dinerSubtotal: Double { dinerItems.reduce(0) { total, item in total + (item.price / Double(item.assignedDinerIds.count)) } }
    var dinerTax: Double { billSubtotal == 0 ? 0 : bill.taxAmount * (dinerSubtotal / billSubtotal) }
    var dinerTip: Double { billSubtotal == 0 ? 0 : bill.tipAmount * (dinerSubtotal / billSubtotal) }
    var dinerTotal: Double { dinerSubtotal + dinerTax + dinerTip }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Circle().fill(Color(hex: diner.hexColor).opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(Text(diner.initials).pieFont(.caption, weight: .bold).foregroundColor(Color(hex: diner.hexColor)))
                
                Text(diner.name)
                    .pieFont(.headline, weight: .bold)
                    .foregroundColor(.pieCoffee)
                
                Spacer()
                
                Text(String(format: "$%.2f", dinerTotal))
                    .pieFont(.title3, weight: .heavy)
                    .foregroundColor(Color(hex: diner.hexColor))
            }
            .padding(16)
            
            if !dinerItems.isEmpty {
                Divider().opacity(0.5)
                
                VStack(spacing: 12) {
                    ForEach(dinerItems) { item in
                        HStack(alignment: .top) {
                            Text(item.name)
                                .pieFont(.caption, weight: .medium)
                                .foregroundColor(.pieCoffee.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Text(String(format: "$%.2f", item.price / Double(item.assignedDinerIds.count)))
                                .pieFont(.caption, weight: .bold)
                                .foregroundColor(.pieCoffee)
                        }
                    }
                    
                    if dinerTax > 0 || dinerTip > 0 {
                        Divider().padding(.vertical, 4)
                        if dinerTax > 0 {
                            HStack {
                                Text("Tax")
                                    .pieFont(.caption, weight: .medium)
                                    .foregroundColor(.pieCoffee.opacity(0.6))
                                Spacer()
                                Text(String(format: "$%.2f", dinerTax))
                                    .pieFont(.caption, weight: .medium)
                                    .foregroundColor(.pieCoffee.opacity(0.6))
                            }
                        }
                        if dinerTip > 0 {
                            HStack {
                                Text("Tip")
                                    .pieFont(.caption, weight: .medium)
                                    .foregroundColor(.pieCoffee.opacity(0.6))
                                Spacer()
                                Text(String(format: "$%.2f", dinerTip))
                                    .pieFont(.caption, weight: .medium)
                                    .foregroundColor(.pieCoffee.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.3))
            }
        }
        .background(Color.pieCream)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.pieCoffee.opacity(0.1), lineWidth: 1))
    }
}
