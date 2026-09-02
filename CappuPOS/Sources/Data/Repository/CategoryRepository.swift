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

        let category = Category(name: trimmed, description: description)
        context.insert(category)
        _ = try? context.save()
        return category
    }

    public func fetchAll() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>()
        return try context.fetch(descriptor)
    }
}