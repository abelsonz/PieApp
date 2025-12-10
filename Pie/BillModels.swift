import SwiftUI
import SwiftData

// MARK: - The Parent Bill (Receipt)
@Model
class Bill: Identifiable {
    var id: UUID
    var title: String
    var date: Date
    var taxAmount: Double
    var tipAmount: Double
    var isPaid: Bool
    
    // Relationships
    @Relationship(deleteRule: .cascade) var items: [BillItem]
    @Relationship(deleteRule: .cascade) var diners: [Diner]
    
    init(title: String = "New Bill", taxAmount: Double = 0, tipAmount: Double = 0) {
        self.id = UUID()
        self.title = title
        self.date = Date()
        self.taxAmount = taxAmount
        self.tipAmount = tipAmount
        self.isPaid = false
        self.items = []
        self.diners = []
    }
    
    var totalAmount: Double {
        let itemsTotal = items.reduce(0) { $0 + $1.price }
        return itemsTotal + taxAmount + tipAmount
    }
}

// NOTE: I removed the manual 'extension Bill: Hashable' here.
// SwiftData's @Model macro adds Hashable support automatically.

// MARK: - The Item
@Model
class BillItem: Identifiable, Codable {
    var id: UUID
    var name: String
    var price: Double
    var assignedDinerIds: [UUID]
    
    init(name: String, price: Double) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.assignedDinerIds = []
    }
    
    var pricePerShare: Double {
        if assignedDinerIds.isEmpty { return 0 }
        return price / Double(assignedDinerIds.count)
    }
    
    // MARK: - Codable (For AI Parser)
    enum CodingKeys: String, CodingKey {
        case name, price
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(Double.self, forKey: .price)
        self.assignedDinerIds = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
    }
}

// MARK: - The Diner
@Model
class Diner: Identifiable {
    var id: UUID
    var name: String
    var hexColor: String
    
    init(name: String, color: Color) {
        self.id = UUID()
        self.name = name
        self.hexColor = color.toHex() ?? "f59e0b"
    }
    
    var color: Color {
        Color(hex: hexColor)
    }
    
    var initials: String {
        String(name.prefix(1)).uppercased()
    }
}

// Helper: Color <-> Hex
extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "f59e0b"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
