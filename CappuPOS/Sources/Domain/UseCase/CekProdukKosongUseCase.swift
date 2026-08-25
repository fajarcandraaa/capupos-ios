import Foundation
import SwiftData

public final class CekProdukKosongUseCase {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func isEmpty() -> Bool {
        let fetchDescriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.isDeleted == false })
        guard let count = try? context.fetchCount(fetchDescriptor) else { return true }
        return count == 0
    }
}