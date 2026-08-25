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
}