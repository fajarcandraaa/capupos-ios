import SwiftUI
import SwiftData

/// Laporan histori perubahan stok (TASK-006 FR-09.2): daftar StockHistoryEntry
/// terbaru dulu, nama produk via ProductRepository.fetchById.
public struct HistoriStokView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \StockHistoryEntry.timestamp, order: .reverse) private var entries: [StockHistoryEntry]

    public init() {}

    private var productRepository: ProductRepository {
        ProductRepository(context: modelContext)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if entries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(entries) { entry in
                        entryRow(entry)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.white)
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

            Text("Histori Stok")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Belum ada perubahan stok")
                .font(.system(size: 14))
                .foregroundColor(.cappuMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func entryRow(_ entry: StockHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(productName(entry.productID))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cappuTextPrimary)
            Text("\(entry.quantityBefore) → \(entry.quantityAfter)")
                .font(.system(size: 13))
                .foregroundColor(entry.quantityAfter < entry.quantityBefore ? .red : .cappuPrimary)
            Text(entry.timestamp, style: .date)
                .font(.system(size: 11))
                .foregroundColor(.cappuMuted)
        }
    }

    private func productName(_ id: UUID) -> String {
        (try? productRepository.fetchById(id: id))?.name ?? "Produk dihapus"
    }
}
