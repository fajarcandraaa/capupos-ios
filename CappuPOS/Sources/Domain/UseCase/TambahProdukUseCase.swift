import Foundation
import SwiftData

public final class TambahProdukUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func execute(
        nama: String,
        harga: Double,
        kategoriID: UUID? = nil,
        deskripsi: String? = nil,
        imageData: Data? = nil
    ) throws -> Product {
        try productRepository.add(
            name: nama,
            price: harga,
            description: deskripsi,
            categoryID: kategoriID,
            imageData: imageData
        )
    }
}
