import SwiftUI
import SwiftData

/// Riwayat transaksi lunas (TASK-006 FR-07): filter kategori/tanggal/metode +
/// search. Swipe: sembunyikan (FR-07.3, tanpa pengaruh laporan), hapus
/// (FR-08: lunas → soft delete).
public struct RiwayatListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Category> { _ in true }) private var categories: [Category]

    @State private var searchText = ""
    @State private var filter = FilterRiwayat()
    @State private var showingFilter = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    public init() {}

    private var orders: [Order] {
        let repo = OrderRepository(context: modelContext)
        let productRepo = ProductRepository(context: modelContext)
        let useCase = FetchRiwayatUseCase(orderRepository: repo, productRepository: productRepo)
        return (try? useCase.execute(filter: filter, searchText: searchText)) ?? []
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            filterBar
            if orders.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(orders) { order in
                        orderRow(order)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showingFilter) {
            RiwayatFilterView(filter: $filter, categories: categories)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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

            Text("Riwayat")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.cappuMuted)
            TextField("Cari transaksi", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.cappuTextPrimary)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Color.cappuPanel)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Button {
                showingFilter = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(filter.isActive ? "Filter Aktif" : "Filter")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(filter.isActive ? .white : .cappuPrimary)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(filter.isActive ? Color.cappuPrimary : Color.cappuPanel)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)

            if filter.isActive {
                Button("Reset") {
                    filter = FilterRiwayat()
                }
                .font(.system(size: 13))
                .foregroundColor(.cappuMuted)
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Belum ada riwayat transaksi")
                .font(.system(size: 14))
                .foregroundColor(.cappuMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func orderRow(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(orderLabel(order))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cappuTextPrimary)
                Spacer()
                Text(PriceFormatter.format(order.subtotal))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cappuTextPrimary)
            }
            Text(order.tanggal, style: .date)
                .font(.system(size: 12))
                .foregroundColor(.cappuMuted)
            if let metode = order.metodeBayar {
                Text(metodeLabel(metode))
                    .font(.system(size: 11))
                    .foregroundColor(.cappuPrimary)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                hapus(order)
            } label: {
                Label("Hapus", systemImage: "trash")
            }
            Button {
                sembunyikan(order)
            } label: {
                Label("Sembunyikan", systemImage: "eye.slash")
            }
            .tint(.cappuPrimary)
        }
    }

    // MARK: - Actions

    private func orderLabel(_ order: Order) -> String {
        if let first = order.items.first {
            let base = first.deskripsi ?? "Item"
            return order.items.count > 1 ? "\(base) +\(order.items.count - 1)" : base
        }
        return "Transaksi"
    }

    private func metodeLabel(_ value: String) -> String {
        switch value {
        case MetodeBayar.tunai: return "Tunai"
        case MetodeBayar.nonTunai: return "Non-Tunai"
        default: return value
        }
    }

    private func sembunyikan(_ order: Order) {
        let repo = OrderRepository(context: modelContext)
        do {
            try repo.sembunyikan(orderID: order.id)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func hapus(_ order: Order) {
        let useCase = HapusTransaksiUseCase(orderRepository: OrderRepository(context: modelContext))
        do {
            try useCase.execute(orderID: order.id)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}
