import Foundation
import SwiftData

public final class OrderRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    /// Semua transaksi tertunda "Belum Bayar", terbaru dulu, soft-delete disembunyikan.
    public func fetchBelumBayar() throws -> [Order] {
        let belumBayar = OrderStatus.belumBayar
        let descriptor = FetchDescriptor<Order>(
            predicate: #Predicate { $0.status == belumBayar && $0.isDeleted == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func fetchById(id: UUID) throws -> Order? {
        let descriptor = FetchDescriptor<Order>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    // MARK: - Create

    /// Simpan transaksi (Open Bill): status awal "belum_bayar", subtotal dihitung dari item.
    public func add(
        items: [OrderItem],
        statusPo: String? = nil,
        catatan: String? = nil
    ) throws -> Order {
        let subtotal = items.reduce(0.0) { $0 + ($1.price * Double($1.quantity)) }
        let order = Order(
            status: OrderStatus.belumBayar,
            statusPo: statusPo,
            subtotal: subtotal,
            catatan: catatan?.isEmpty == true ? nil : catatan,
            tanggal: Date()
        )
        context.insert(order)
        for item in items {
            item.order = order
            context.insert(item)
        }
        try context.save()
        return order
    }

    /// Tambah item ke transaksi existing (flow Duplikasi: item produk/manual ke bill sama).
    public func addItem(orderID: UUID, item: OrderItem) throws -> Order {
        let order = try fetchOrder(id: orderID)
        item.order = order
        context.insert(item)
        order.subtotal += item.price * Double(item.quantity)
        order.updatedAt = Date()
        try context.save()
        return order
    }

    // MARK: - Update

    /// Hapus item dari order; item dihapus fisik, subtotal dihitung ulang.
    public func removeItem(orderID: UUID, itemID: UUID) throws -> Order {
        let order = try fetchOrder(id: orderID)
        guard let item = order.items.first(where: { $0.id == itemID }) else {
            throw NSError(
                domain: "OrderRepository", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Item tidak ditemukan"]
            )
        }
        context.delete(item)
        order.subtotal = order.items
            .filter { $0.id != itemID }
            .reduce(0.0) { $0 + ($1.price * Double($1.quantity)) }
        order.updatedAt = Date()
        try context.save()
        return order
    }

    /// Ubah item existing (flow Ubah): kuantitas/harga/deskripsi + hitung ulang subtotal.
    public func updateItem(
        orderID: UUID,
        itemID: UUID,
        quantity: Int,
        price: Double? = nil,
        deskripsi: String? = nil
    ) throws -> Order {
        let order = try fetchOrder(id: orderID)
        guard let item = order.items.first(where: { $0.id == itemID }) else {
            throw NSError(
                domain: "OrderRepository", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Item tidak ditemukan"]
            )
        }
        item.quantity = quantity
        if let price = price {
            item.price = price
        }
        if let deskripsi = deskripsi {
            item.deskripsi = deskripsi.isEmpty ? nil : deskripsi
        }
        item.updatedAt = Date()
        order.subtotal = order.items.reduce(0.0) { $0 + ($1.price * Double($1.quantity)) }
        order.updatedAt = Date()
        try context.save()
        return order
    }

    // MARK: - Status

    /// Ubah status PO. FR-05.5: transisi `selesai` -> `dibatalkan` dilarang.
    public func updateStatusPo(orderID: UUID, to newStatus: String) throws -> Order {
        let order = try fetchOrder(id: orderID)
        guard StatusPO.allowedTargets(from: order.statusPo).contains(newStatus) else {
            throw NSError(
                domain: "OrderRepository", code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Transisi status PO tidak diizinkan (FR-05.5)"]
            )
        }
        order.statusPo = newStatus
        order.updatedAt = Date()
        try context.save()
        return order
    }

    /// Hapus mode PO (kembali ke transaksi biasa, statusPo = nil).
    public func clearStatusPo(orderID: UUID) throws -> Order {
        let order = try fetchOrder(id: orderID)
        order.statusPo = nil
        order.updatedAt = Date()
        try context.save()
        return order
    }

    /// Soft-delete order (riwayat tetap ada untuk FR-07).
    public func softDelete(orderID: UUID) throws {
        let order = try fetchOrder(id: orderID)
        order.isDeleted = true
        order.deletedAt = Date()
        order.updatedAt = Date()
        try context.save()
    }

    // MARK: - Private

    private func fetchOrder(id: UUID) throws -> Order {
        guard let order = try fetchById(id: id) else {
            throw NSError(
                domain: "OrderRepository", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Order tidak ditemukan"]
            )
        }
        return order
    }
}
