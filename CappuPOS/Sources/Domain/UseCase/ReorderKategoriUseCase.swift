import Foundation
import SwiftData

public final class ReorderKategoriUseCase {
    private let categoryRepository: CategoryRepository

    public init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    public func execute(categoryIDs: [UUID]) -> Bool {
        categoryRepository.reorder(ids: categoryIDs)
    }
}
