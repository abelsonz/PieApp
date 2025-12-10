import SwiftUI

struct SlicingView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var diners: [Diner] = [
        Diner(name: "You", color: .pieCrust)
    ]
    
    @State private var activeDinerId: UUID?
    @State private var items: [BillItem]
    @State private var taxAmount: Double
    @State private var showCheckout = false
    
    // Rename Logic
    @State private var dinerToRename: Diner?
    @State private var renameText: String = ""
    @State private var showRenameAlert = false
    
    init(initialItems: [BillItem], initialTax: Double) {
        _items = State(initialValue: initialItems)
        _taxAmount = State(initialValue: initialTax)
    }
    
    var activeDinerTotal: Double {
        guard let activeId = activeDinerId else { return 0 }
        return items.reduce(0) { total, item in
            if item.assignedDinerIds.contains(activeId) {
                return total + item.pricePerShare
            }
            return total
        }
    }

    var body: some View {
        ZStack {
            Color.pieCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 1. Top Bar
                VStack(spacing: 15) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundColor(.pieCoffee)
                                .padding(10)
                                .background(Color.pieCream)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        
                        Spacer()
                        Text("Slice up the Pie")
                            .pieFont(.title3, weight: .heavy)
                            .foregroundColor(.pieCoffee)
                        Spacer()
                        
                        Button(action: addDiner) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.pieCrust)
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .padding(.bottom, 10)
                    
                    // Avatars
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Array(diners.enumerated()), id: \.element.id) { index, diner in
                                DinerAvatar(
                                    diner: diner,
                                    isSelected: activeDinerId == diner.id,
                                    // LOGIC FIX: Never allow deletion of the first diner (owner)
                                    onDelete: index == 0 ? nil : {
                                        deleteDiner(diner)
                                    }
                                )
                                .onTapGesture {
                                    withAnimation { activeDinerId = diner.id }
                                }
                                .onLongPressGesture(minimumDuration: 0.125) {
                                    startRenaming(diner)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 15)
                    }
                }
                .background(Color.pieCream)
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 5)
                .zIndex(1)
                
                // MARK: - 2. Scrollable List
                ScrollView {
                    VStack(spacing: 12) {
                        if items.isEmpty {
                            Text("No items found.")
                                .pieFont(.body)
                                .opacity(0.5)
                                .padding(.top, 50)
                        } else {
                            Text("Tap items to assign to \(activeDinerName)")
                                .pieFont(.caption)
                                .opacity(0.6)
                                .padding(.top, 20)
                            
                            ForEach($items) { $item in
                                MultiDinerItemRow(
                                    item: $item,
                                    activeDinerId: activeDinerId,
                                    diners: diners
                                )
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
                
                // MARK: - 3. Fixed Footer
                VStack {
                    Button(action: { showCheckout = true }) {
                        Text("Split")
                            .pieFont(.title3, weight: .bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.pieCrust)
                            .clipShape(Capsule())
                            .shadow(color: Color.pieCrust.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .padding(.bottom, 0)
                }
                .background(Color.pieCream)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
            }
            .ignoresSafeArea(edges: .top)
        }
        .onAppear {
            if activeDinerId == nil {
                activeDinerId = diners.first?.id
            }
        }
        .sheet(isPresented: $showCheckout) {
            CheckoutView(
                items: items,
                diners: diners,
                initialTax: taxAmount,
                onFinish: { dismiss() } // This dismisses SlicingView after checkout
            )
        }
        .toolbar(.hidden, for: .tabBar)
        
        // Rename Alert
        .alert("Rename Diner", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Save") { saveDinerName() }
        } message: {
            Text("Enter a new name for this diner.")
        }
    }
    
    // MARK: - Helpers
    var activeDinerName: String {
        diners.first(where: { $0.id == activeDinerId })?.name ?? "Diner"
    }
    
    func addDiner() {
        let colors: [Color] = [.pieCrust, Color.Fruit.cherry, Color.Fruit.blueberry, Color.Fruit.keyLime, Color.Fruit.plum]
        let nextIndex = diners.count
        let color = colors[nextIndex % colors.count]
        
        let newDiner = Diner(name: "Diner \(nextIndex + 1)", color: color)
        diners.append(newDiner)
        
        withAnimation {
            activeDinerId = newDiner.id
        }
    }
    
    func deleteDiner(_ diner: Diner) {
        withAnimation {
            if let index = diners.firstIndex(where: { $0.id == diner.id }) {
                diners.remove(at: index)
            }
            for i in 0..<items.count {
                items[i].assignedDinerIds.removeAll(where: { $0 == diner.id })
            }
            if activeDinerId == diner.id {
                activeDinerId = diners.first?.id
            }
        }
    }
    
    func startRenaming(_ diner: Diner) {
        dinerToRename = diner
        renameText = diner.name
        showRenameAlert = true
    }
    
    func saveDinerName() {
        guard let dinerToRename = dinerToRename, !renameText.isEmpty else { return }
        if let index = diners.firstIndex(where: { $0.id == dinerToRename.id }) {
            diners[index].name = renameText
        }
    }
}

// MARK: - Subviews

struct DinerAvatar: View {
    let diner: Diner
    let isSelected: Bool
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    if isSelected {
                        Circle().stroke(diner.color, lineWidth: 3).frame(width: 58, height: 58)
                    }
                    Circle().fill(diner.color.opacity(isSelected ? 1.0 : 0.3)).frame(width: 50, height: 50)
                    Text(diner.initials).pieFont(.headline, weight: .bold).foregroundColor(isSelected ? .white : .pieCoffee)
                }
                
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.Fruit.cherry)
                            .background(Circle().fill(Color.white).padding(2))
                    }
                    .offset(x: 5, y: -5)
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(), value: isSelected)
            
            Text(diner.name).pieFont(.caption2, weight: .semibold).opacity(isSelected ? 1.0 : 0.5)
        }
    }
}

struct MultiDinerItemRow: View {
    @Binding var item: BillItem
    var activeDinerId: UUID?
    var diners: [Diner]
    
    var isAssignedToActive: Bool {
        guard let id = activeDinerId else { return false }
        return item.assignedDinerIds.contains(id)
    }
    
    var body: some View {
        Button(action: toggleAssignment) {
            HStack(alignment: .center) {
                
                // Left: Name + Dots
                HStack(alignment: .center, spacing: 8) {
                    Text(item.name)
                        .pieFont(.body, weight: .medium)
                        .opacity(item.assignedDinerIds.isEmpty ? 0.6 : 1.0)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    if !item.assignedDinerIds.isEmpty {
                        HStack(spacing: -8) {
                            ForEach(diners.filter { item.assignedDinerIds.contains($0.id) }) { diner in
                                Circle()
                                    .fill(diner.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Right: Price
                // LAYOUT FIX: Use ZStack alignment to prevent height changes
                ZStack(alignment: .trailing) {
                    // 1. The main price. We dim it if split.
                    Text(String(format: "$%.2f", item.price))
                        .pieFont(item.assignedDinerIds.count > 1 ? .caption : .body, weight: item.assignedDinerIds.count > 1 ? .regular : .semibold)
                        .strikethrough(item.assignedDinerIds.count > 1)
                        .opacity(item.assignedDinerIds.count > 1 ? 0.5 : 1.0)
                        // If split, we move this text up slightly to make room for the "ea" text
                        // OR we can just rely on the Overlay for the "ea" text
                        .offset(y: item.assignedDinerIds.count > 1 ? -10 : 0)
                    
                    // 2. The split price. We show this in an overlay or below without pushing boundaries?
                    // Actually, let's keep it clean: Vertical stack with fixed frame is safest,
                    // but overlay prevents parent expansion best.
                    if item.assignedDinerIds.count > 1 {
                        Text(String(format: "$%.2f ea", item.pricePerShare))
                            .pieFont(.caption, weight: .bold)
                            .foregroundColor(.pieCrust)
                            .offset(y: 10) // Position below the strikethrough price
                    }
                }
                .frame(height: 40) // FORCE a fixed height for the price container so it never jumps
            }
            .padding()
            .background(isAssignedToActive ? Color.pieCrust.opacity(0.1) : Color.pieCream)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isAssignedToActive ? getActiveColor() : Color.black.opacity(0.05), lineWidth: isAssignedToActive ? 2 : 1)
            )
            .scaleEffect(isAssignedToActive ? 1.01 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func toggleAssignment() {
        guard let activeId = activeDinerId else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if item.assignedDinerIds.contains(activeId) {
                if let index = item.assignedDinerIds.firstIndex(of: activeId) {
                    item.assignedDinerIds.remove(at: index)
                }
            } else {
                item.assignedDinerIds.append(activeId)
            }
        }
    }
    
    func getActiveColor() -> Color {
        diners.first(where: { $0.id == activeDinerId })?.color ?? .pieCrust
    }
}
