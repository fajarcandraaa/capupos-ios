import SwiftData

public final class CategoryRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func create(name: String, description: String?) -> Category {
        let category = Category(name: name, description: description)
        context.insert(category)
        _ = try? context.save()
        return category
    }

    public func fetchAll() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>()
        return try context.fetch(descriptor)
    }
}