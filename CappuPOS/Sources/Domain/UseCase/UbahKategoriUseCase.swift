import Foundation
import SwiftData

public final class UbahKategoriUseCase {
    private let categoryRepository: CategoryRepository

    public init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    public func execute(id: UUID, name: String, description: String?) -> Category? {
        categoryRepository.update(id: id, name: name, description: description)
    }
}
