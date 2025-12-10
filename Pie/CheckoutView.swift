import SwiftUI
import SwiftData

struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState // Access AppState
    
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
                    .padding(.top, 30)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // 1. Math Section (Tax & Tip)
                        VStack(spacing: 20) {
                            HStack {
                                Text("Tax").pieFont(.body, weight: .bold).foregroundColor(.pieCoffee).opacity(0.8)
                                Spacer()
                                TextField("0.00", value: $taxAmount, format: .currency(code: "USD"))
                                    .keyboardType(.decimalPad)
                                    .focused($isInputFocused)
                                    .multilineTextAlignment(.trailing)
                                    .pieFont(.body, weight: .semibold)
                                    .padding(10)
                                    .background(Color.pieCream)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pieCoffee.opacity(0.2), lineWidth: 1))
                                    .frame(width: 120)
                            }
                            
                            Divider().opacity(0.5)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Tip").pieFont(.body, weight: .bold).foregroundColor(.pieCoffee).opacity(0.8)
                                    Spacer()
                                    
                                    if selectedTipPercent == nil {
                                        TextField("0.00", value: $tipAmount, format: .currency(code: "USD"))
                                            .keyboardType(.decimalPad)
                                            .focused($isInputFocused)
                                            .multilineTextAlignment(.trailing)
                                            .pieFont(.body, weight: .bold)
                                            .foregroundColor(.pieCrust)
                                            .padding(8)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pieCrust, lineWidth: 2))
                                            .frame(width: 120)
                                    } else {
                                        Text(String(format: "$%.2f", tipAmount))
                                            .pieFont(.body, weight: .bold)
                                            .foregroundColor(.pieCrust)
                                    }
                                }
                                
                                HStack(spacing: 10) {
                                    ForEach([0.15, 0.20, 0.25], id: \.self) { pct in
                                        Button(action: { selectedTipPercent = pct; tipAmount = billSubtotal * pct; isInputFocused = false }) {
                                            Text("\(Int(pct * 100))%")
                                                .pieFont(.caption, weight: .bold)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(selectedTipPercent == pct ? Color.pieCrust : Color.pieCream)
                                                .foregroundColor(selectedTipPercent == pct ? .white : .pieCoffee)
                                                .cornerRadius(8)
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pieCoffee.opacity(0.2), lineWidth: 1))
                                        }
                                    }
                                    Button(action: { selectedTipPercent = nil; isInputFocused = true }) {
                                        Text("Custom")
                                            .pieFont(.caption, weight: .bold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(selectedTipPercent == nil ? Color.pieCrust : Color.pieCream)
                                            .foregroundColor(selectedTipPercent == nil ? .white : .pieCoffee)
                                            .cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pieCoffee.opacity(0.2), lineWidth: 1))
                                    }
                                }
                            }
                        }
                        .padding().background(Color.pieCream).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pieCoffee.opacity(0.15), lineWidth: 1)).shadow(color: Color.pieCoffee.opacity(0.05), radius: 10, y: 5)
                        
                        // 2. Diner Breakdown
                        Text("Diner Breakdown").pieFont(.headline, weight: .bold).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 5).padding(.top, 10)
                        
                        ForEach(diners) { diner in
                            let breakdown = calculateBreakdown(for: diner)
                            VStack(spacing: 8) {
                                HStack {
                                    Circle().fill(diner.color.opacity(0.2)).frame(width: 36, height: 36).overlay(Text(diner.initials).pieFont(.caption, weight: .bold).foregroundColor(diner.color))
                                    Text(diner.name).pieFont(.body, weight: .bold).foregroundColor(.pieCoffee)
                                    Spacer()
                                    Text(String(format: "$%.2f", breakdown.total)).pieFont(.body, weight: .heavy).foregroundColor(.pieCoffee)
                                }
                                Divider().opacity(0.3)
                                HStack {
                                    Label(String(format: "$%.2f Food", breakdown.subtotal), systemImage: "fork.knife")
                                    Spacer()
                                    Label(String(format: "$%.2f Tax", breakdown.tax), systemImage: "building.columns")
                                    Spacer()
                                    Label(String(format: "$%.2f Tip", breakdown.tip), systemImage: "heart.fill").foregroundColor(.pieCrust)
                                }.font(.system(size: 10, weight: .semibold)).foregroundColor(.gray)
                            }
                            .padding().background(Color.pieCream).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pieCoffee.opacity(0.1), lineWidth: 1))
                        }
                        
                        // Grand Total
                        HStack {
                            Text("Grand Total").pieFont(.headline, weight: .bold)
                            Spacer()
                            Text(String(format: "$%.2f", billTotal)).pieFont(.title2, weight: .heavy).foregroundColor(.pieCrust)
                        }
                        .padding(.top, 20).padding(.horizontal)
                    }
                    .padding(.horizontal).padding(.bottom, 100)
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
                        .cornerRadius(30)
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
        
        // Navigation Logic:
        // 1. Close Checkout Sheet
        dismiss()
        
        // 2. Trigger "onFinish" which closes SlicingView (parent sheet)
        onFinish()
        
        // 3. Navigate to Pantry Tab and Push View
        appState.navigateToPantry(with: newBill)
    }
}
