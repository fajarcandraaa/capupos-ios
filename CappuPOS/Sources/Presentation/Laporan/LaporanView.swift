import SwiftUI
import SwiftData
import Charts

/// Laporan penjualan (TASK-006 FR-09.1 / FR-09.3): overview card (total,
/// jumlah transaksi, periode, metode terpopuler) + grafik tren Swift Charts +
/// filter/search (pakai logika yang sama dengan Riwayat FR-07).
public struct LaporanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var categories: [Category]

    @State private var searchText = ""
    @State private var filter = FilterRiwayat()
    @State private var showingFilter = false

    public init() {}

    private var overview: LaporanOverview {
        let useCase = FetchLaporanUseCase(
            orderRepository: OrderRepository(context: modelContext),
            productRepository: ProductRepository(context: modelContext)
        )
        return (try? useCase.execute(filter: filter, searchText: searchText))
            ?? LaporanOverview(periodAwal: nil, periodAkhir: nil, totalPenjualan: 0, jumlahTransaksi: 0, metodeBayarTerpopuler: nil, trendPerHari: [])
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 16) {
                    overviewCard
                    trendChart
                }
                .padding(16)
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showingFilter) {
            RiwayatFilterView(filter: $filter, categories: categories)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.cappuTextPrimary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Text("Laporan")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()

            Button {
                showingFilter = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 16))
                    .foregroundColor(filter.isActive ? .cappuPrimary : .cappuMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Penjualan")
                .font(.system(size: 12))
                .foregroundColor(.cappuMuted)
            Text(PriceFormatter.format(overview.totalPenjualan))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            HStack(spacing: 16) {
                stat("Transaksi", "\(overview.jumlahTransaksi)")
                if let metode = overview.metodeBayarTerpopuler {
                    stat("Metode", metodeLabel(metode))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cappuPanel)
        .cornerRadius(12)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.cappuMuted)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cappuTextPrimary)
        }
    }

    @ViewBuilder
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tren Penjualan")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cappuTextPrimary)

            if overview.trendPerHari.isEmpty {
                Text("Belum ada data")
                    .font(.system(size: 13))
                    .foregroundColor(.cappuMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(overview.trendPerHari) { point in
                    BarMark(
                        x: .value("Tanggal", point.tanggal, unit: .day),
                        y: .value("Total", point.total)
                    )
                    .foregroundStyle(Color.cappuPrimary)
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(Color.cappuPanel)
        .cornerRadius(12)
    }

    private func metodeLabel(_ value: String) -> String {
        switch value {
        case MetodeBayar.tunai: return "Tunai"
        case MetodeBayar.nonTunai: return "Non-Tunai"
        default: return value
        }
    }
}
