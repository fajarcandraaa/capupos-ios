import SwiftData
import Foundation

public final class CategoryRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func create(name: String, description: String?) -> Category? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Check duplicate
        var descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { cat in cat.name == trimmed }
        )
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []
        if !existing.isEmpty {
            return nil // Category dengan nama sama sudah exist
        }

        let maxOrder = (try? context.fetch(FetchDescriptor<Category>()).map(\.order).max()) ?? -1
        let category = Category(name: trimmed, description: description, order: maxOrder + 1)
        context.insert(category)
        _ = try? context.save()
        return category
    }

    public func fetchAll() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>()
        return try context.fetch(descriptor)
    }

    public func update(id: UUID, name: String, description: String?) -> Category? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Check duplicate (exclude self)
        var descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { cat in cat.name == trimmed && cat.id != id }
        )
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []
        if !existing.isEmpty {
            return nil
        }

        let descriptor2 = FetchDescriptor<Category>(
            predicate: #Predicate { cat in cat.id == id }
        )
        guard let category = (try? context.fetch(descriptor2))?.first else { return nil }
        category.name = trimmed
        category.details = description
        _ = try? context.save()
        return category
    }

    public func delete(id: UUID) -> Bool {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { cat in cat.id == id }
        )
        guard let category = (try? context.fetch(descriptor))?.first else { return false }

        // Null out products' categoryID (active products only)
        let prodDescriptor = FetchDescriptor<Product>(
            predicate: #Predicate { prod in prod.categoryID == id && prod.isDeleted == false }
        )
        let products = (try? context.fetch(prodDescriptor)) ?? []
        products.forEach { $0.categoryID = nil }

        context.delete(category)
        _ = try? context.save()
        return true
    }

    public func reorder(ids: [UUID]) -> Bool {
        do {
            for (index, id) in ids.enumerated() {
                let descriptor = FetchDescriptor<Category>(
                    predicate: #Predicate { cat in cat.id == id }
                )
                guard let category = try context.fetch(descriptor).first else { continue }
                category.order = index
            }
            try context.save()
            return true
        } catch {
            return false
        }
    }

    public func countProductsByCategory(categoryID: UUID) throws -> Int {
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { prod in prod.categoryID == categoryID && prod.isDeleted == false }
        )
        return try context.fetchCount(descriptor)
    }
}