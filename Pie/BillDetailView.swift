import SwiftUI
import SwiftData

struct BillDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var bill: Bill
    
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
                    Text("Split Details")
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
                
                // Content (Interactive)
                ScrollView {
                    interactiveContent
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .gesture(DragGesture().onEnded { value in
            if value.translation.width > 60 { dismiss() }
        })
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                renderImage()
            }
        }
        .onChange(of: bill.title) { _, _ in
            renderImage()
        }
    }
    
    // MARK: - 1. Interactive View (For the User)
    var interactiveContent: some View {
        VStack(spacing: 25) {
            // Header Section
            VStack(spacing: 5) {
                // Editable Text Field
                TextField("Receipt Name", text: $bill.title)
                    .pieFont(.body, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .opacity(0.6)
                    .submitLabel(.done)
                
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
            
            // Breakdown Section
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
                        // Show Venmo Button here
                        DinerSummaryCard(diner: diner, bill: bill, billSubtotal: billSubtotal, showActions: true)
                            .padding(.horizontal)
                    }
                }
            }
            
            Text("Split with Pie")
                .pieFont(.caption, weight: .bold)
                .foregroundColor(.pieCrust)
                .padding(.top, 20)
        }
    }
    
    // MARK: - 2. Snapshot View (Clean for Image)
    var snapshotTemplate: some View {
        VStack(spacing: 25) {
            // Header Section
            VStack(spacing: 5) {
                // FIXED: Use Text instead of TextField (No yellow bar!)
                Text(bill.title)
                    .pieFont(.body, weight: .semibold)
                    .multilineTextAlignment(.center)
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
            
            // Breakdown Section
            VStack(alignment: .leading, spacing: 15) {
                Text("Split Breakdown")
                    .pieFont(.title3, weight: .bold)
                    .foregroundColor(.pieCoffee)
                    .padding(.horizontal)
                
                ForEach(bill.diners) { diner in
                    // FIXED: Hide Venmo Button (Cleaner look)
                    DinerSummaryCard(diner: diner, bill: bill, billSubtotal: billSubtotal, showActions: false)
                        .padding(.horizontal)
                }
            }
            
            Text("Split with Pie")
                .pieFont(.caption, weight: .bold)
                .foregroundColor(.pieCrust)
                .padding(.top, 20)
        }
        .padding(20)
        .background(Color.pieCream)
        .frame(width: 375) // Fixed width for perfect export
    }
    
    @MainActor
    func renderImage() {
        // Render the CLEAN snapshot template, not the interactive view
        let renderer = ImageRenderer(content: snapshotTemplate)
        renderer.scale = 3.0
        
        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
        }
    }
}

// Updated Card to handle hiding buttons
struct DinerSummaryCard: View {
    let diner: Diner; let bill: Bill; let billSubtotal: Double
    var showActions: Bool = true // Default to true
    
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
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(diner.name)
                        .pieFont(.headline, weight: .bold)
                        .foregroundColor(.pieCoffee)
                }
                
                Spacer()
                
                // Hide button if generating screenshot
                if showActions && diner.name.lowercased() != "you" {
                    Button(action: openVenmo) {
                        HStack(spacing: 4) {
                            Text("Venmo Request")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                }
                
                Text(String(format: "$%.2f", dinerTotal))
                    .pieFont(.title3, weight: .heavy)
                    .foregroundColor(Color(hex: diner.hexColor))
                    .padding(.leading, 8)
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
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.pieCoffee.opacity(0.05), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
    }
    
    // Deep Link Logic
    func openVenmo() {
        let note = "Dinner (Split with Pie)"
        let amountString = String(format: "%.2f", dinerTotal)
        let urlString = "venmo://paycharge?txn=pay&amount=\(amountString)&note=\(note)"
        
        if let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            UIApplication.shared.open(url) { success in
                if !success {
                    if let webUrl = URL(string: "https://venmo.com/?txn=charge&amount=\(amountString)&note=\(note)") {
                        UIApplication.shared.open(webUrl)
                    }
                }
            }
        }
    }
}
