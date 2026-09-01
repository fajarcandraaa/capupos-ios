import Foundation
import SwiftData

public final class ProductRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func isEmpty() -> Bool {
        let fetchDescriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.isDeleted == false })
        guard let count = try? context.fetchCount(fetchDescriptor) else { return true }
        return count == 0
    }

    public func fetchAll() throws -> [Product] {
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.isDeleted == false })
        return try context.fetch(descriptor)
    }

    public func fetchByCategory(categoryID: UUID) throws -> [Product] {
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.categoryID == categoryID && $0.isDeleted == false }
        )
        return try context.fetch(descriptor)
    }

    public func search(query: String) throws -> [Product] {
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { product in
                product.isDeleted == false &&
                (product.name.localizedStandardContains(query) ||
                 (product.productDescription?.localizedStandardContains(query) ?? false))
            }
        )
        return try context.fetch(descriptor)
    }

    public func fetchById(id: UUID) throws -> Product? {
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    public func add(
        name: String,
        price: Double,
        description: String? = nil,
        categoryID: UUID? = nil,
        imageData: Data? = nil,
        stockQuantity: Int = 0,
        stockMinimal: Int = 0
    ) throws -> Product {
        let product = Product(
            name: name,
            price: price,
            categoryID: categoryID,
            image: imageData,
            productDescription: description?.isEmpty == true ? nil : description,
            stockQuantity: stockQuantity,
            stockMinimal: stockMinimal
        )
        context.insert(product)
        try context.save()
        return product
    }

    public func update(
        id: UUID,
        name: String,
        price: Double,
        categoryID: UUID? = nil,
        imageData: Data? = nil,
        description: String? = nil
    ) throws -> Product {
        guard let product = try fetchById(id: id) else {
            throw NSError(domain: "ProductRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Product not found"])
        }
        product.name = name
        product.price = price
        product.categoryID = categoryID
        if let imageData = imageData {
            product.image = imageData
        }
        product.productDescription = description?.isEmpty == true ? nil : description
        product.updatedAt = Date()
        try context.save()
        return product
    }

    public func delete(id: UUID) throws {
        guard let product = try fetchById(id: id) else {
            throw NSError(domain: "ProductRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Product not found"])
        }
        product.isDeleted = true
        product.updatedAt = Date()
        try context.save()
    }
}