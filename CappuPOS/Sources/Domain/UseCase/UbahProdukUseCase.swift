import Foundation
import SwiftData

public final class UbahProdukUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func execute(
        id: UUID,
        nama: String,
        harga: Double,
        kategoriID: UUID? = nil,
        deskripsi: String? = nil,
        imageData: Data? = nil
    ) throws -> Product {
        try productRepository.update(
            id: id,
            name: nama,
            price: harga,
            categoryID: kategoriID,
            imageData: imageData,
            description: deskripsi
        )
    }
}
