import Foundation
import SwiftData

/// Filter riwayat (FR-07.1): kategori produk, rentang tanggal, metode bayar.
/// Semua field opsional; nil = tanpa filter.
public struct FilterRiwayat {
    public var kategoriID: UUID?
    public var dariTanggal: Date?
    public var sampaiTanggal: Date?
    public var metodeBayar: String?

    public init(
        kategoriID: UUID? = nil,
        dariTanggal: Date? = nil,
        sampaiTanggal: Date? = nil,
        metodeBayar: String? = nil
    ) {
        self.kategoriID = kategoriID
        self.dariTanggal = dariTanggal
        self.sampaiTanggal = sampaiTanggal
        self.metodeBayar = metodeBayar
    }

    /// Ada filter aktif? Untuk menampilkan indikator + tombol reset di UI.
    public var isActive: Bool {
        kategoriID != nil || dariTanggal != nil || sampaiTanggal != nil || metodeBayar != nil
    }
}

/// Ambil riwayat transaksi lunas + filter in-memory (kategori/tanggal/metode)
/// + search (FR-07.2). Filter di UseCase, bukan predicate SwiftData — DECISIONS.md
/// [2026-09-13] poin 8 (kategori via relasi, tidak bisa #Predicate murni).
public final class FetchRiwayatUseCase {
    private let orderRepository: OrderRepository
    private let productRepository: ProductRepository

    public init(orderRepository: OrderRepository, productRepository: ProductRepository) {
        self.orderRepository = orderRepository
        self.productRepository = productRepository
    }

    public func execute(filter: FilterRiwayat = FilterRiwayat(), searchText: String = "") throws -> [Order] {
        let orders = try orderRepository.fetchRiwayatLunas()
        return Self.apply(filter, searchText: searchText, to: orders, productRepository: productRepository)
    }

    /// Logika filter bersama — dipakai ulang FetchLaporanUseCase (FR-09.3
    /// memakai filter/search yang sama dengan FR-07.1/07.2).
    static func apply(
        _ filter: FilterRiwayat,
        searchText: String,
        to orders: [Order],
        productRepository: ProductRepository
    ) -> [Order] {
        var result = orders

        if let kategoriID = filter.kategoriID {
            result = result.filter { order in
                order.items.contains { item in
                    guard let productID = item.productID,
                          let product = try? productRepository.fetchById(id: productID) else { return false }
                    return product.categoryID == kategoriID
                }
            }
        }
        if let dari = filter.dariTanggal {
            result = result.filter { $0.tanggal >= dari }
        }
        if let sampai = filter.sampaiTanggal {
            result = result.filter { $0.tanggal <= sampai }
        }
        if let metode = filter.metodeBayar {
            result = result.filter { $0.metodeBayar == metode }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { order in
                let catatan = order.catatan?.lowercased() ?? ""
                let metode = order.metodeBayar?.lowercased() ?? ""
                if catatan.contains(query) || metode.contains(query) { return true }
                return order.items.contains { item in
                    let deskripsi = item.deskripsi?.lowercased() ?? ""
                    if deskripsi.contains(query) { return true }
                    guard let productID = item.productID,
                          let product = try? productRepository.fetchById(id: productID) else { return false }
                    return product.name.lowercased().contains(query)
                }
            }
        }

        return result
    }
}
