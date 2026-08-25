import SwiftData
import Foundation

@Model
public final class Product {
    var id: UUID
    var name: String
    var price: Double
    var categoryID: UUID?
    var image: Data?

    init(id: UUID = UUID(), name: String, price: Double, categoryID: UUID? = nil, image: Data? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.categoryID = categoryID
        self.image = image
    }
}

@Model
public final class Category {
    var id: UUID
    var name: String
    var details: String?

    init(id: UUID = UUID(), name: String, details: String? = nil) {
        self.id = id
        self.name = name
        self.details = details
    }
}

@Model
public final class Customer {
    var id: UUID
    var name: String
    var phone: String
    var email: String?
    var loyaltyPoints: Int

    init(id: UUID = UUID(), name: String, phone: String, email: String? = nil, loyaltyPoints: Int = 0) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.loyaltyPoints = loyaltyPoints
    }
}

public enum OrderStatus: String, CaseIterable, Codable {
    case pending
    case confirmed
    case processing
    case completed
    case cancelled
    case refunded
}

@Model
public final class Order {
    var id: UUID
    var customerID: UUID?
    var total: Double
    var status: String
    var createdAt: Date
    var completedAt: Date?
    var orderDescription: String?

    init(id: UUID = UUID(), customerID: UUID? = nil, total: Double, status: OrderStatus = .pending, createdAt: Date = Date(), completedAt: Date? = nil, orderDescription: String? = nil) {
        self.id = id
        self.customerID = customerID
        self.total = total
        self.status = status.rawValue
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.orderDescription = orderDescription
    }
}

@Model
public final class OrderItem {
    var id: UUID
    var orderID: UUID
    var productID: UUID
    var quantity: Int
    var price: Double

    init(id: UUID = UUID(), orderID: UUID, productID: UUID, quantity: Int, price: Double) {
        self.id = id
        self.orderID = orderID
        self.productID = productID
        self.quantity = quantity
        self.price = price
    }
}

public enum PaymentStatus: String, CaseIterable, Codable {
    case pending
    case completed
    case failed
    case refunded
}

@Model
public final class Payment {
    var id: UUID
    var orderID: UUID
    var amount: Double
    var method: String
    var status: String
    var transactionID: String?
    var createdAt: Date

    init(id: UUID = UUID(), orderID: UUID, amount: Double, method: String, status: PaymentStatus = .pending, transactionID: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.orderID = orderID
        self.amount = amount
        self.method = method
        self.status = status.rawValue
        self.transactionID = transactionID
        self.createdAt = createdAt
    }
}

@Model
public final class User {
    var id: UUID
    var username: String
    var passwordHash: String
    var role: String
    var name: String

    init(id: UUID = UUID(), username: String, passwordHash: String, role: String, name: String) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.role = role
        self.name = name
    }
}

@Model
public final class Store {
    var id: UUID
    var name: String
    var address: String
    var phone: String
    var openingHours: String

    init(id: UUID = UUID(), name: String, address: String, phone: String, openingHours: String) {
        self.id = id
        self.name = name
        self.address = address
        self.phone = phone
        self.openingHours = openingHours
    }
}

public struct CapuPOSDataSchema {
    public static let schema = Schema([
        Product.self,
        Category.self,
        Customer.self,
        Order.self,
        OrderItem.self,
        Payment.self,
        User.self,
        Store.self
    ])
}

public func initializeCapuPOSContainer() throws -> ModelContainer {
    let modelConfiguration = ModelConfiguration(schema: CapuPOSDataSchema.schema, isStoredInMemoryOnly: false)
    return try ModelContainer(for: CapuPOSDataSchema.schema, configurations: [modelConfiguration])
}
