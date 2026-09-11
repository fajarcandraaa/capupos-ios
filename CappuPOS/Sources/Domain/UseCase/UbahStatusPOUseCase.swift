import Foundation
import SwiftData

/// Ubah status PO 5 tahap. FR-05.5: transisi `selesai` -> `dibatalkan` ditolak repository.
public final class UbahStatusPOUseCase {
    private let orderRepository: OrderRepository

    public init(orderRepository: OrderRepository) {
        self.orderRepository = orderRepository
    }

    public func execute(orderID: UUID, statusPo: String) throws -> Order {
        try orderRepository.updateStatusPo(orderID: orderID, to: statusPo)
    }
}
