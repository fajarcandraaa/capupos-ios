import SwiftData

@MainActor final class Container {
    static let shared = Container()

    let modelContainer: ModelContainer

    private init() {
        do {
            modelContainer = try Self.createContainer()
        } catch {
            fatalError("Failed to initialize container: \(error)")
        }
    }

    private static func createContainer() throws -> ModelContainer {
        // TODO: Move schema definition to DataModel.swift
        // Current implementation inline for SourceKit compatibility
        let schema = Schema([
            Product.self,
            Category.self,
            Customer.self,
            Order.self,
            OrderItem.self,
            Payment.self,
            User.self,
            Store.self
        ])

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func resolve<T>() -> T {
        switch T.self {
        case is ModelContainer.Type:
            return modelContainer as! T
        default:
            fatalError("Unsupported dependency type: \(T.self)")
        }
    }
}