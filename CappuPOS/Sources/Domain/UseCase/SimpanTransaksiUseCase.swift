import Foundation
import SwiftData

/// Simpan transaksi tertunda (Open Bill) dengan status awal "belum_bayar".
public final class SimpanTransaksiUseCase {
    private let orderRepository: OrderRepository

    public init(orderRepository: OrderRepository) {
        self.orderRepository = orderRepository
    }

    public func execute(
        items: [OrderItem],
        statusPo: String? = nil,
        catatan: String? = nil
    ) throws -> Order {
        try orderRepository.add(items: items, statusPo: statusPo, catatan: catatan)
    }
}
