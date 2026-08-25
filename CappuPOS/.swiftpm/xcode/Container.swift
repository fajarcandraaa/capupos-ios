import SwiftData

// NOTE:
// SourceKit Context Mode may not resolve cross-file types reliably in some editor contexts.
// To keep builds stable, we intentionally define the SwiftData Schema inline here instead of
// referencing a schema from another file (e.g., CapuPOSDataModel.swift).
// When building the full Xcode project (with proper targets and build settings), you can
// switch this to use a shared schema definition.

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
