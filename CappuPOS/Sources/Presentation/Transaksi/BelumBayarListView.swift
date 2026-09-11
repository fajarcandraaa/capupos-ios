import SwiftUI
import SwiftData

/// List transaksi tertunda "Belum Bayar" dikelompokkan per tanggal (FR-05/FR-07).
/// Aksi per order: Ubah (item + status PO), Duplikasi, Hapus (soft-delete).
public struct BelumBayarListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var orders: [Order]

    @State private var orderToEdit: Order?
    @State private var showingAlert = false
    @State private var alertMessage = ""

    public init() {}

    private var belumBayar: [Order] {
        orders.filter { $0.status == OrderStatus.belumBayar && !$0.isDeleted }
    }

    private var groupedByDate: [(day: Date, orders: [Order])] {
        let grouped = Dictionary(grouping: belumBayar) { order in
            Calendar.current.startOfDay(for: order.tanggal)
        }
        return grouped
            .map { (day: $0.key, orders: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    public var body: some View {
        VStack(spacing: 0) {
            header
            if belumBayar.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Color.white)
        .sheet(item: $orderToEdit) { order in
            OrderDetailEditView(order: order)
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

            Text("Belum Bayar")
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
            Text("Belum ada transaksi tertunda")
                .font(.system(size: 14))
                .foregroundColor(.cappuMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        List {
            ForEach(groupedByDate, id: \.day) { group in
                Section(header: Text(Self.dateFormatter.string(from: group.day))) {
                    ForEach(group.orders) { order in
                        orderRow(order)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func orderRow(_ order: Order) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(orderLabel(order))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cappuTextPrimary)
                Text("\(order.items.count) item · \(PriceFormatter.format(order.subtotal))")
                    .font(.system(size: 12))
                    .foregroundColor(.cappuMuted)
                if let statusPo = order.statusPo {
                    Text("PO: \(poLabel(statusPo))")
                        .font(.system(size: 11))
                        .foregroundColor(.cappuPrimary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            orderToEdit = order
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                delete(order)
            } label: {
                Label("Hapus", systemImage: "trash")
            }
            Button {
                duplicate(order)
            } label: {
                Label("Duplikasi", systemImage: "doc.on.doc")
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

    private func delete(_ order: Order) {
        let repository = OrderRepository(context: modelContext)
        do {
            try repository.softDelete(orderID: order.id)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func duplicate(_ order: Order) {
        let repository = OrderRepository(context: modelContext)
        let useCase = SimpanTransaksiUseCase(orderRepository: repository)
        let copies = order.items.map { item in
            OrderItem(
                productID: item.productID,
                quantity: item.quantity,
                price: item.price,
                deskripsi: item.deskripsi
            )
        }
        do {
            _ = try useCase.execute(items: copies, statusPo: order.statusPo, catatan: order.catatan)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func poLabel(_ value: String) -> String {
        switch value {
        case StatusPO.menungguKonfirmasi: return "Menunggu Konfirmasi"
        case StatusPO.diproses: return "Diproses"
        case StatusPO.siap: return "Siap"
        case StatusPO.selesai: return "Selesai"
        case StatusPO.dibatalkan: return "Dibatalkan"
        default: return value
        }
    }
}
