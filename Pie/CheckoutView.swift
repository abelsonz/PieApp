import SwiftUI
import SwiftData

struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    @FocusState private var isInputFocused: Bool
    
    var items: [BillItem]
    var diners: [Diner]
    var onFinish: () -> Void
    
    @State private var taxAmount: Double
    @State private var tipAmount: Double = 0.00
    @State private var selectedTipPercent: Double? = 0.20
    
    init(items: [BillItem], diners: [Diner], initialTax: Double, onFinish: @escaping () -> Void) {
        self.items = items
        self.diners = diners
        self.onFinish = onFinish
        _taxAmount = State(initialValue: initialTax)
        
        let subtotal = items.reduce(0) { $0 + $1.price }
        _tipAmount = State(initialValue: subtotal * 0.20)
    }
    
    var billSubtotal: Double { items.reduce(0) { $0 + $1.price } }
    var billTotal: Double { billSubtotal + taxAmount + tipAmount }
    
    var body: some View {
        ZStack {
            Color.pieCream.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Final Slice")
                    .pieFont(.title2, weight: .bold)
                    .foregroundColor(.pieCoffee)
                    .padding(.top, 30)
                
                ScrollView {
                    VStack(spacing: 25) { // Increased spacing for breathing room
                        
                        // 1. Math Section (Tax & Tip)
                        VStack(spacing: 15) {
                            // Tax Row
                            HStack {
                                Text("Tax")
                                    .pieFont(.body, weight: .bold)
                                    .foregroundColor(.pieCoffee).opacity(0.8)
                                Spacer()
                                TextField("0.00", value: $taxAmount, format: .currency(code: "USD"))
                                    .keyboardType(.decimalPad)
                                    .focused($isInputFocused)
                                    .multilineTextAlignment(.trailing)
                                    .pieFont(.body, weight: .semibold)
                                    .foregroundColor(.pieCoffee)
                                    .padding(12)
                                    .background(Color.white) // Clean White Background
                                    .cornerRadius(12)
                                    .frame(width: 120)
                            }
                            
                            // Tip Row
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Tip")
                                        .pieFont(.body, weight: .bold)
                                        .foregroundColor(.pieCoffee).opacity(0.8)
                                    Spacer()
                                    
                                    if selectedTipPercent == nil {
                                        TextField("0.00", value: $tipAmount, format: .currency(code: "USD"))
                                            .keyboardType(.decimalPad)
                                            .focused($isInputFocused)
                                            .multilineTextAlignment(.trailing)
                                            .pieFont(.body, weight: .bold)
                                            .foregroundColor(.pieCrust) // Orange text for Tip
                                            .padding(12)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .frame(width: 120)
                                    } else {
                                        Text(String(format: "$%.2f", tipAmount))
                                            .pieFont(.body, weight: .bold)
                                            .foregroundColor(.pieCrust)
                                            .padding(.trailing, 12)
                                    }
                                }
                                
                                // Tip Buttons
                                HStack(spacing: 10) {
                                    ForEach([0.15, 0.20, 0.25], id: \.self) { pct in
                                        Button(action: { selectedTipPercent = pct; tipAmount = billSubtotal * pct; isInputFocused = false }) {
                                            Text("\(Int(pct * 100))%")
                                                .pieFont(.caption, weight: .bold)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                // Active: Orange, Inactive: White (Cleaner than Cream)
                                                .background(selectedTipPercent == pct ? Color.pieCrust : Color.white)
                                                .foregroundColor(selectedTipPercent == pct ? .white : .pieCoffee)
                                                .cornerRadius(10)
                                        }
                                    }
                                    Button(action: { selectedTipPercent = nil; isInputFocused = true }) {
                                        Text("Custom")
                                            .pieFont(.caption, weight: .bold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedTipPercent == nil ? Color.pieCrust : Color.white)
                                            .foregroundColor(selectedTipPercent == nil ? .white : .pieCoffee)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.5)) // Glassy container
                        .cornerRadius(20)
                        
                        // 2. Diner Breakdown
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Diner Breakdown")
                                .pieFont(.headline, weight: .bold)
                                .foregroundColor(.pieCoffee)
                                .padding(.leading, 5)
                            
                            ForEach(diners) { diner in
                                let breakdown = calculateBreakdown(for: diner)
                                VStack(spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: diner.hexColor).opacity(0.15))
                                            .frame(width: 36, height: 36)
                                            .overlay(Text(diner.initials).pieFont(.caption, weight: .bold).foregroundColor(Color(hex: diner.hexColor)))
                                        
                                        Text(diner.name)
                                            .pieFont(.body, weight: .bold)
                                            .foregroundColor(.pieCoffee)
                                        
                                        Spacer()
                                        
                                        Text(String(format: "$%.2f", breakdown.total))
                                            .pieFont(.body, weight: .heavy)
                                            .foregroundColor(Color(hex: diner.hexColor))
                                    }
                                    
                                    Divider().opacity(0.3)
                                    
                                    HStack {
                                        Label(String(format: "$%.2f", breakdown.subtotal), systemImage: "fork.knife")
                                        Spacer()
                                        Label(String(format: "$%.2f", breakdown.tax), systemImage: "building.columns")
                                        Spacer()
                                        Label(String(format: "$%.2f", breakdown.tip), systemImage: "star.fill")
                                            .foregroundColor(.pieCrust)
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white) // CHANGED: White card for better contrast
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
                            }
                        }
                        
                        // Grand Total
                        HStack {
                            Text("Grand Total")
                                .pieFont(.headline, weight: .bold)
                                .foregroundColor(.pieCoffee)
                            Spacer()
                            Text(String(format: "$%.2f", billTotal))
                                .pieFont(.title, weight: .heavy) // Slightly larger
                                .foregroundColor(.pieCrust)
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            
            // MARK: - Save Button
            VStack {
                Spacer()
                Button(action: saveAndClose) {
                    Text("Add to Pantry")
                        .pieFont(.headline, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pieCrust)
                        .clipShape(Capsule()) // CHANGED: Explicit Capsule for consistency
                        .shadow(color: Color.pieCrust.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isInputFocused = false }.foregroundColor(.pieCrust)
            }
        }
    }
    
    func calculateBreakdown(for diner: Diner) -> (subtotal: Double, tax: Double, tip: Double, total: Double) {
        let foodShare = items.reduce(0.0) { total, item in if item.assignedDinerIds.contains(diner.id) { return total + item.pricePerShare } else { return total } }
        let ratio = (billSubtotal > 0) ? (foodShare / billSubtotal) : 0
        let taxShare = taxAmount * ratio
        let tipShare = tipAmount * ratio
        return (foodShare, taxShare, tipShare, foodShare + taxShare + tipShare)
    }
    
    func saveAndClose() {
        let newBill = Bill(title: "Receipt \(Date().formatted(.dateTime.month().day()))", taxAmount: taxAmount, tipAmount: tipAmount)
        newBill.isPaid = true
        newBill.items = items
        newBill.diners = diners
        modelContext.insert(newBill)
        
        dismiss()
        onFinish()
        appState.navigateToPantry(with: newBill)
    }
}
