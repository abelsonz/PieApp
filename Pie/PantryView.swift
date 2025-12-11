import SwiftUI
import SwiftData

struct PantryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \Bill.date, order: .reverse) var recentBills: [Bill]
    
    // Rename Logic
    @State private var billToRename: Bill?
    @State private var renameText: String = ""
    @State private var showRenameAlert = false
    
    var body: some View {
        NavigationStack(path: $appState.pantryPath) {
            ZStack {
                Color.pieCream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Pantry")
                            .pieFont(.largeTitle, weight: .heavy)
                            .foregroundColor(.pieCoffee)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    if recentBills.isEmpty {
                        // Empty State
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "basket")
                                .font(.system(size: 90))
                                .foregroundColor(.pieCoffee.opacity(0.2))
                            
                            VStack(spacing: 8) {
                                Text("The Pantry is Empty")
                                    .pieFont(.title2, weight: .bold)
                                    .foregroundColor(.pieCoffee.opacity(0.6))
                                
                                Text("Your past slices will appear here.")
                                    .pieFont(.body)
                                    .foregroundColor(.pieCoffee)
                                    .opacity(0.6)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 100)
                    } else {
                        List {
                            ForEach(groupedBills.keys.sorted(by: >), id: \.self) { date in
                                Section(header: dateHeader(for: date)) {
                                    ForEach(groupedBills[date]!) { bill in
                                        ZStack {
                                            BillRowCard(bill: bill)
                                            NavigationLink(value: bill) {
                                                EmptyView()
                                            }
                                            .opacity(0)
                                        }
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                        // SWIPE ACTIONS
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteBill(bill)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .tint(Color.Fruit.cherry)
                                        }
                                        // CONTEXT MENU (Rename/Delete)
                                        .contextMenu {
                                            Button {
                                                billToRename = bill
                                                renameText = bill.title
                                                showRenameAlert = true
                                            } label: {
                                                Label("Rename", systemImage: "pencil")
                                            }
                                            
                                            Button(role: .destructive) {
                                                deleteBill(bill)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationDestination(for: Bill.self) { bill in
                BillDetailView(bill: bill)
            }
            // Rename Alert
            .alert("Rename Receipt", isPresented: $showRenameAlert) {
                TextField("New Name", text: $renameText)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if let bill = billToRename {
                        bill.title = renameText
                    }
                }
            } message: {
                Text("Enter a new name for this receipt.")
            }
        }
    }
    
    // Helpers
    var groupedBills: [Date: [Bill]] {
        Dictionary(grouping: recentBills) { bill in
            Calendar.current.startOfDay(for: bill.date)
        }
    }
    
    func dateHeader(for date: Date) -> some View {
        let title: String
        if Calendar.current.isDateInToday(date) { title = "Today" }
        else if Calendar.current.isDateInYesterday(date) { title = "Yesterday" }
        else { title = date.formatted(date: .abbreviated, time: .omitted) }
        
        return Text(title)
            .pieFont(.caption, weight: .bold)
            .foregroundColor(.pieCoffee.opacity(0.5))
            .textCase(.uppercase)
            .padding(.vertical, 8)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .background(Color.pieCream)
    }
    
    func deleteBill(_ bill: Bill) {
        withAnimation {
            modelContext.delete(bill)
        }
    }
}

struct BillRowCard: View {
    let bill: Bill
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(bill.title)
                    .pieFont(.body, weight: .bold)
                    .foregroundColor(.pieCoffee)
                    .lineLimit(1)
                
                Text(bill.date.formatted(date: .omitted, time: .shortened))
                    .pieFont(.caption)
                    .foregroundColor(.pieCoffee.opacity(0.5))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "$%.2f", bill.totalAmount))
                    .pieFont(.headline, weight: .heavy)
                    .foregroundColor(.pieCrust)
                
                if !bill.diners.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(bill.diners.prefix(4)) { diner in
                            Circle()
                                .fill(Color(hex: diner.hexColor))
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color.pieCream, lineWidth: 1.5))
                        }
                        if bill.diners.count > 4 {
                            Circle()
                                .fill(Color.pieCoffee.opacity(0.1))
                                .frame(width: 20, height: 20)
                                .overlay(Text("+\(bill.diners.count - 4)").font(.system(size: 8, weight: .bold)).foregroundColor(.pieCoffee))
                                .overlay(Circle().stroke(Color.pieCream, lineWidth: 1.5))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pieCoffee.opacity(0.08), lineWidth: 1))
        .shadow(color: Color.pieCoffee.opacity(0.02), radius: 5, y: 2)
    }
}
