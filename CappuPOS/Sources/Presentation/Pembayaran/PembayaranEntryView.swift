import SwiftUI
import SwiftData

/// Entry layar Pembayaran (TASK-006): daftar transaksi "Belum Bayar".
/// Tap baris -> form bayar; swipe "Tandai Lunas" -> bayar tunai cepat (FR-07.4
/// "tandai belum-bayar jadi lunas langsung" — nominal diterima = subtotal).
public struct PembayaranEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var orders: [Order]

    @State private var orderToPay: Order?
    @State private var showingAlert = false
    @State private var alertMessage = ""

    public init() {}

    private var belumBayar: [Order] {
        let pending = orders.filter { order in
            order.status == OrderStatus.belumBayar && !order.isDeleted
        }
        return pending.sorted { $0.createdAt > $1.createdAt }
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if belumBayar.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(belumBayar) { order in
                        orderRow(order)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.white)
        .sheet(item: $orderToPay) { order in
            PembayaranView(order: order)
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

            Text("Pembayaran")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
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

    private func orderRow(_ order: Order) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(orderLabel(order))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cappuTextPrimary)
                Text("\(order.items.count) item · \(PriceFormatter.format(order.subtotal))")
                    .font(.system(size: 12))
                    .foregroundColor(.cappuMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.cappuMuted)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            orderToPay = order
        }
        .swipeActions(edge: .trailing) {
            Button {
                tandaiLunas(order)
            } label: {
                Label("Tandai Lunas", systemImage: "checkmark")
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

    /// FR-07.4: tandai lunas langsung — tunai, nominal = subtotal, kembalian 0.
    private func tandaiLunas(_ order: Order) {
        let useCase = BayarTransaksiUseCase(
            orderRepository: OrderRepository(context: modelContext),
            productRepository: ProductRepository(context: modelContext)
        )
        do {
            _ = try useCase.execute(
                orderID: order.id,
                metodeBayar: MetodeBayar.tunai,
                nominalDiterima: order.subtotal
            )
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}
