import SwiftData
import Foundation

@Model
public final class Product {
    public var id: UUID
    public var name: String
    public var price: Double
    public var categoryID: UUID?
    public var image: Data?
    public var productDescription: String?
    public var stockTracked: Bool = false
    public var stockQuantity: Int?
    public var stockMinimal: Int?
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    public var isDeleted: Bool = false

    public init(
        id: UUID = UUID(),
        name: String,
        price: Double,
        categoryID: UUID? = nil,
        image: Data? = nil,
        productDescription: String? = nil,
        stockTracked: Bool = false,
        stockQuantity: Int? = 0,
        stockMinimal: Int? = 0
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.categoryID = categoryID
        self.image = image
        self.productDescription = productDescription
        self.stockTracked = stockTracked
        self.stockQuantity = stockQuantity
        self.stockMinimal = stockMinimal
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
public final class Category {
    public var id: UUID
    public var name: String
    public var details: String?

    public init(id: UUID = UUID(), name: String, description: String? = nil) {
        self.id = id
        self.name = name
        self.details = description
    }
}