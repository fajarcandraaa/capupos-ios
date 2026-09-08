import Foundation
import SwiftData

public final class TambahKategoriUseCase {
    private let categoryRepository: CategoryRepository

    public init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    public func execute(name: String, description: String?) -> Category? {
        categoryRepository.create(name: name, description: description)
    }
}
