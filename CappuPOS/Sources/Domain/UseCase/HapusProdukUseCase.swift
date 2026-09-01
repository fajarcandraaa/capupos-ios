import Foundation
import SwiftData

public final class HapusProdukUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func execute(id: UUID) throws {
        try productRepository.delete(id: id)
    }
}
