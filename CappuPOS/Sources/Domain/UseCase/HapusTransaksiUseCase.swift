import Foundation
import SwiftData

/// Hapus transaksi (FR-08): lunas -> soft delete (riwayat/laporan tetap),
/// belum_bayar -> hard delete (hapus fisik). Dispatch berdasar status.
public final class HapusTransaksiUseCase {
    private let orderRepository: OrderRepository

    public init(orderRepository: OrderRepository) {
        self.orderRepository = orderRepository
    }

    public func execute(orderID: UUID) throws {
        guard let order = try orderRepository.fetchById(id: orderID) else {
            throw NSError(
                domain: "HapusTransaksiUseCase", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Order tidak ditemukan"]
            )
        }
        if order.status == OrderStatus.lunas {
            try orderRepository.softDelete(orderID: orderID)
        } else {
            try orderRepository.hardDelete(orderID: orderID)
        }
    }
}
