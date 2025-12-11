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
    
    // Add/Edit Item Logic
    @State private var showItemSheet = false
    @State private var itemToEdit: BillItem? // If set, we are editing; if nil, adding
    
    // Delete Item Logic
    @State private var itemToDelete: BillItem?
    
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
                                .background(Color.white.opacity(0.5)) // Glassy style
                                .clipShape(Circle())
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
                                    isSelected: activeDinerId == diner.id
                                )
                                .onTapGesture {
                                    withAnimation { activeDinerId = diner.id }
                                }
                                .contextMenu {
                                    Button {
                                        startRenaming(diner)
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    
                                    if index != 0 {
                                        Button(role: .destructive) {
                                            deleteDiner(diner)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
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
                                // Extended Context Menu
                                .contextMenu {
                                    // 1. Split All
                                    Button {
                                        withAnimation {
                                            item.assignedDinerIds = diners.map { $0.id }
                                        }
                                    } label: {
                                        Label("Split with Everyone", systemImage: "person.3.fill")
                                    }
                                    
                                    // 2. Edit
                                    Button {
                                        itemToEdit = item
                                        showItemSheet = true
                                    } label: {
                                        Label("Edit Item", systemImage: "pencil")
                                    }
                                    
                                    // 3. Delete
                                    Button(role: .destructive) {
                                        itemToDelete = item
                                    } label: {
                                        Label("Delete Item", systemImage: "trash")
                                    }
                                }
                            }
                            
                            // "Add Item" Button
                            Button(action: {
                                itemToEdit = nil // Ensure we are in "Add" mode
                                showItemSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Item")
                                }
                                .pieFont(.body, weight: .semibold)
                                .foregroundColor(.pieCrust)
                                .padding(.vertical, 15)
                                .frame(maxWidth: .infinity)
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
                onFinish: { dismiss() }
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
        
        // ADD / EDIT Item Sheet
        .sheet(isPresented: $showItemSheet) {
            AddItemSheet(
                initialName: itemToEdit?.name ?? "",
                initialPrice: itemToEdit != nil ? String(format: "%.2f", itemToEdit!.price) : ""
            ) { name, price in
                if let editingItem = itemToEdit {
                    // Update existing
                    if let index = items.firstIndex(where: { $0.id == editingItem.id }) {
                        items[index].name = name
                        items[index].price = price
                    }
                } else {
                    // Add new
                    addNewItem(name: name, price: price)
                }
                itemToEdit = nil
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
        
        // Delete Item Sheet
        .sheet(item: $itemToDelete) { item in
            DeleteItemSheet(itemName: item.name) {
                deleteItem(item)
            }
            .presentationDetents([.fraction(0.3)])
            .presentationDragIndicator(.visible)
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
    
    func addNewItem(name: String, price: Double) {
        let newItem = BillItem(name: name, price: price)
        withAnimation {
            items.append(newItem)
        }
    }
    
    func deleteItem(_ item: BillItem) {
        withAnimation {
            items.removeAll(where: { $0.id == item.id })
        }
        itemToDelete = nil
    }
}

// MARK: - Subviews

struct DinerAvatar: View {
    let diner: Diner
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    if isSelected {
                        Circle()
                            .stroke(diner.color, lineWidth: 3)
                            .frame(width: 58, height: 58)
                    }
                    Circle()
                        .fill(diner.color.opacity(isSelected ? 1.0 : 0.3))
                        .frame(width: 50, height: 50)
                    
                    Text(diner.initials)
                        .pieFont(.headline, weight: .bold)
                        .foregroundColor(isSelected ? .white : .pieCoffee)
                }
            }
            .frame(width: 60, height: 60)
            .contentShape(Rectangle())
            
            Text(diner.name)
                .pieFont(.caption2, weight: .semibold)
                .opacity(isSelected ? 1.0 : 0.5)
        }
        .padding(.horizontal, 4)
    }
}

struct AddItemSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var initialName: String = ""
    var initialPrice: String = ""
    var onAdd: (String, Double) -> Void
    
    @State private var name = ""
    @State private var price = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.pieCream.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(initialName.isEmpty ? "Add Item" : "Edit Item")
                    .pieFont(.title3, weight: .bold)
                    .foregroundColor(.pieCoffee)
                    .padding(.top, 20)
                
                VStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        if name.isEmpty {
                            Text("Item Name (e.g. Fries)")
                                .pieFont(.body, weight: .medium)
                                .foregroundColor(.pieCoffee.opacity(0.5))
                        }
                        TextField("", text: $name)
                            .pieFont(.body, weight: .medium)
                            .foregroundColor(.pieCoffee)
                            .tint(.pieCrust)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    ZStack(alignment: .leading) {
                        if price.isEmpty {
                            Text("Price (0.00)")
                                .pieFont(.body, weight: .bold)
                                .foregroundColor(.pieCoffee.opacity(0.5))
                        }
                        TextField("", text: $price)
                            .keyboardType(.decimalPad)
                            .pieFont(.body, weight: .bold)
                            .foregroundColor(.pieCoffee)
                            .tint(.pieCrust)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button(action: {
                    if let priceValue = Double(price), !name.isEmpty {
                        onAdd(name, priceValue)
                        dismiss()
                    }
                }) {
                    Text(initialName.isEmpty ? "Add to Bill" : "Save Changes")
                        .pieFont(.headline, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty || price.isEmpty ? Color.pieCrust.opacity(0.3) : Color.pieCrust)
                        .cornerRadius(16)
                }
                .disabled(name.isEmpty || price.isEmpty)
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .onAppear {
            name = initialName
            price = initialPrice
            isFocused = true
        }
    }
}

struct DeleteItemSheet: View {
    let itemName: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.pieCream.ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("Delete Item?")
                    .pieFont(.title3, weight: .bold)
                    .foregroundColor(.pieCoffee)
                    .padding(.top, 25)
                
                Text("Are you sure you want to remove\n\"\(itemName)\"?")
                    .pieFont(.body)
                    .foregroundColor(.pieCoffee.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 15) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .pieFont(.headline, weight: .bold)
                            .foregroundColor(.pieCoffee)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pieCoffee.opacity(0.1), lineWidth: 1))
                    }
                    
                    Button(action: {
                        onConfirm()
                        dismiss()
                    }) {
                        Text("Delete")
                            .pieFont(.headline, weight: .bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.Fruit.cherry)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
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
                ZStack(alignment: .trailing) {
                    Text(String(format: "$%.2f", item.price))
                        .pieFont(item.assignedDinerIds.count > 1 ? .caption : .body, weight: item.assignedDinerIds.count > 1 ? .regular : .semibold)
                        .strikethrough(item.assignedDinerIds.count > 1)
                        .opacity(item.assignedDinerIds.count > 1 ? 0.5 : 1.0)
                        .offset(y: item.assignedDinerIds.count > 1 ? -10 : 0)
                    
                    if item.assignedDinerIds.count > 1 {
                        Text(String(format: "$%.2f ea", item.pricePerShare))
                            .pieFont(.caption, weight: .bold)
                            .foregroundColor(.pieCrust)
                            .offset(y: 10)
                    }
                }
                .frame(height: 40)
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
