import SwiftUI
import SwiftData

/// Detail transaksi lunas (TASK-009 AC2): tampilkan order + items, tombol cetak
/// (share StrukView logic via UIActivityViewController).
public struct RiwayatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let order: Order

    @State private var showingStruk = false
    @State private var productNames: [UUID: String] = [:]

    /// Query semua produk (termasuk deleted) — untuk lookup nama bahkan jika produk sudah terhapus.
    /// Mirroring perilaku GenerateStrukUseCase.resolveNamaItem (gunakan fetchById, bukan filter).
    @Query private var allProducts: [Product]

    public var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Order metadata
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tanggal")
                                .foregroundColor(.cappuMuted)
                            Spacer()
                            Text(order.tanggal, style: .date)
                                .font(.system(size: 14, weight: .semibold))
                        }

                        if let metode = order.metodeBayar {
                            HStack {
                                Text("Metode")
                                    .foregroundColor(.cappuMuted)
                                Spacer()
                                Text(metodeLabel(metode))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.cappuPanel)
                    .cornerRadius(8)

                    // Items
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Item")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cappuTextPrimary)

                        ForEach(order.items, id: \.id) { item in
                            itemRow(item)
                        }
                    }

                    // Subtotal
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Total")
                                .foregroundColor(.cappuMuted)
                            Spacer()
                            Text(PriceFormatter.format(order.subtotal))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.cappuPrimary)
                        }
                    }
                    .padding(12)
                    .background(Color.cappuPanel)
                    .cornerRadius(8)
                }
                .padding(16)
            }
            .background(Color.white)

            // Tombol cetak
            Button(action: { showingStruk = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Cetak")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.cappuPrimary)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .cornerRadius(8)
            }
            .padding(16)
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showingStruk) {
            StrukView(orderID: order.id)
        }
        .task {
            loadProductNames()
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

            Text("Detail Transaksi")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func itemRow(_ item: OrderItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(itemLabel(item))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cappuTextPrimary)
                Text("\(item.quantity)x · \(PriceFormatter.format(item.price))")
                    .font(.system(size: 12))
                    .foregroundColor(.cappuMuted)
            }
            Spacer()
            Text(PriceFormatter.format(item.price * Double(item.quantity)))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cappuTextPrimary)
        }
        .padding(12)
        .background(Color.cappuPanel)
        .cornerRadius(6)
    }

    /// Cache nama produk sekali (dict dari @Query `allProducts`), bukan `fetchById` per item
    /// di dalam `ForEach` — hindari O(n) fetch saat render. Termasuk produk terhapus
    /// (soft-deleted) supaya konsisten dengan struk (GenerateStrukUseCase gunakan fetchById
    /// tanpa filter isDeleted).
    private func loadProductNames() {
        productNames = Dictionary(uniqueKeysWithValues: allProducts.map { ($0.id, $0.name) })
    }

    private func itemLabel(_ item: OrderItem) -> String {
        if let deskripsi = item.deskripsi, !deskripsi.isEmpty { return deskripsi }
        if let productID = item.productID, let name = productNames[productID] {
            return name
        }
        return "Item"
    }

    private func metodeLabel(_ value: String) -> String {
        switch value {
        case MetodeBayar.tunai: return "Tunai"
        case MetodeBayar.nonTunai: return "Non-Tunai"
        default: return value
        }
    }
}
