import Foundation
import SwiftData

/// Literal metode bayar (FR-06.1 tunai / FR-06.2 non-tunai). Android belum punya
/// konstanta ekvivalen (kolom `metodeBayar` String bebas) — bila Android nanti
/// mendefinisikan literal, samakan nilainya lintas platform.
public enum MetodeBayar {
    public static let tunai = "tunai"
    public static let nonTunai = "non_tunai"

    /// Urutan kanonik untuk UI picker.
    public static let allInOrder: [String] = [tunai, nonTunai]
}

/// Bayar order "belum_bayar" jadi "lunas" (FR-06) + kurangi stok per item
/// produk + catat StockHistoryEntry (FR-09.2). Item manual (productID == nil)
/// dilewati — tidak ada stok untuk dikurangi. Trigger stok HANYA di alur ini
/// (DECISIONS.md [2026-09-13] poin 7); manual adjustment di luar scope.
public final class BayarTransaksiUseCase {
    private let orderRepository: OrderRepository
    private let productRepository: ProductRepository

    public init(orderRepository: OrderRepository, productRepository: ProductRepository) {
        self.orderRepository = orderRepository
        self.productRepository = productRepository
    }

    public func execute(
        orderID: UUID,
        metodeBayar: String,
        nominalDiterima: Double? = nil,
        catatan: String? = nil
    ) throws -> Order {
        guard let order = try orderRepository.fetchById(id: orderID) else {
            throw NSError(
                domain: "BayarTransaksiUseCase", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Order tidak ditemukan"]
            )
        }
        for item in order.items {
            guard let productID = item.productID else { continue }
            _ = try productRepository.reduceStockQuantity(
                productID: productID,
                by: item.quantity,
                reason: "order_\(orderID.uuidString)"
            )
        }
        return try orderRepository.bayar(
            orderID: orderID,
            metodeBayar: metodeBayar,
            nominalDiterima: nominalDiterima,
            catatan: catatan
        )
    }
}
