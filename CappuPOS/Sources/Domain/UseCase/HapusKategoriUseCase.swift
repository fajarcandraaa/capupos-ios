import Foundation
import SwiftData

public final class HapusKategoriUseCase {
    private let categoryRepository: CategoryRepository

    public init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    public func execute(id: UUID) -> Bool {
        categoryRepository.delete(id: id)
    }

    public func countAffectedProducts(categoryID: UUID) throws -> Int {
        try categoryRepository.countProductsByCategory(categoryID: categoryID)
    }
}
