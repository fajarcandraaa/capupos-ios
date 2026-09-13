import Foundation
import SwiftData

/// Satu titik tren penjualan per hari (FR-09.1) untuk Swift Charts.
public struct LaporanTrendPoint: Identifiable {
    public let id = UUID()
    public let tanggal: Date
    public let total: Double
}

/// Ringkasan laporan penjualan (FR-09.1). Field minimum sesuai DECISIONS.md
/// [2026-09-13] poin 9; period = rentang tanggal order hasil filter.
public struct LaporanOverview {
    public var periodAwal: Date?
    public var periodAkhir: Date?
    public var totalPenjualan: Double
    public var jumlahTransaksi: Int
    public var metodeBayarTerpopuler: String?
    public var trendPerHari: [LaporanTrendPoint]
}

/// Agregasi laporan penjualan dari order lunas (exclude soft-deleted — sudah
/// difilter di `OrderRepository.fetchAllOrders`). Tren dikelompokkan per hari
/// (startOfDay lokal). Filter + search FR-09.3 memakai logika yang sama dengan
/// FR-07 (di UseCase, DECISIONS.md [2026-09-13] poin 8).
public final class FetchLaporanUseCase {
    private let orderRepository: OrderRepository
    private let productRepository: ProductRepository

    public init(orderRepository: OrderRepository, productRepository: ProductRepository) {
        self.orderRepository = orderRepository
        self.productRepository = productRepository
    }

    public func execute(filter: FilterRiwayat = FilterRiwayat(), searchText: String = "") throws -> LaporanOverview {
        let lunas = try orderRepository.fetchAllOrders().filter { $0.status == OrderStatus.lunas }
        let orders = FetchRiwayatUseCase.apply(filter, searchText: searchText, to: lunas, productRepository: productRepository)

        let totalPenjualan = orders.reduce(0.0) { $0 + $1.subtotal }
        let periodAwal = orders.map(\.tanggal).min()
        let periodAkhir = orders.map(\.tanggal).max()

        // Metode terpopuler: hitung frekuensi, ambil tertinggi (tie: nama alfabetis).
        var frekuensi: [String: Int] = [:]
        for order in orders {
            if let metode = order.metodeBayar {
                frekuensi[metode, default: 0] += 1
            }
        }
        let terpopuler = frekuensi.max { lhs, rhs in
            lhs.value == rhs.value ? lhs.key > rhs.key : lhs.value < rhs.value
        }?.key

        let calendar = Calendar.current
        var perHari: [Date: Double] = [:]
        for order in orders {
            let day = calendar.startOfDay(for: order.tanggal)
            perHari[day, default: 0.0] += order.subtotal
        }
        let trend = perHari
            .map { LaporanTrendPoint(tanggal: $0.key, total: $0.value) }
            .sorted { $0.tanggal < $1.tanggal }

        return LaporanOverview(
            periodAwal: periodAwal,
            periodAkhir: periodAkhir,
            totalPenjualan: totalPenjualan,
            jumlahTransaksi: orders.count,
            metodeBayarTerpopuler: terpopuler,
            trendPerHari: trend
        )
    }
}
