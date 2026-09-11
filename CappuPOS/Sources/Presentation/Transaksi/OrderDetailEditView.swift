import SwiftUI
import SwiftData

/// Ubah open bill existing (Figma flow "Langsung - Ubah"): kelola item
/// (tambah manual, duplikasi, hapus, ubah qty) + ubah status PO (FR-05.5).
struct OrderDetailEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let order: Order

    @State private var showingManualItem = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var editingItem: OrderItem?

    private var repository: OrderRepository {
        OrderRepository(context: modelContext)
    }

    var body: some View {
        NavigationView {
            List {
                Section("Item") {
                    ForEach(order.items) { item in
                        itemRow(item)
                    }
                    Button {
                        showingManualItem = true
                    } label: {
                        Label("Tambah item manual", systemImage: "plus")
                    }
                }

                Section("Status PO") {
                    Picker("Status PO", selection: Binding(
                        get: { order.statusPo ?? "" },
                        set: { newValue in
                            if newValue.isEmpty {
                                clearStatusPo()
                            } else {
                                updateStatusPo(newValue)
                            }
                        }
                    )) {
                        Text("Bukan PO").tag("")
                        ForEach(StatusPO.allowedTargets(from: order.statusPo), id: \.self) { value in
                            Text(poLabel(value)).tag(value)
                        }
                    }
                }
            }
            .navigationTitle("Ubah Transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingManualItem) {
            TransaksiManualItemView { nominal, deskripsi in
                addItem(nominal: nominal, deskripsi: deskripsi)
            }
        }
        .sheet(item: $editingItem) { item in
            EditOrderItemView(item: item) { quantity in
                updateItem(item, quantity: quantity)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func itemRow(_ item: OrderItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(itemLabel(item))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cappuTextPrimary)
                Text("\(item.quantity) × \(PriceFormatter.format(item.price))")
                    .font(.system(size: 12))
                    .foregroundColor(.cappuMuted)
            }
            Spacer()
            Button {
                editingItem = item
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.cappuPrimary)
            }
            .buttonStyle(.plain)
            Button {
                duplicateItem(item)
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.cappuPrimary)
            }
            .buttonStyle(.plain)
            Button(role: .destructive) {
                removeItem(item)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }

    private func itemLabel(_ item: OrderItem) -> String {
        if let deskripsi = item.deskripsi, !deskripsi.isEmpty { return deskripsi }
        if let productID = item.productID,
           let product = try? ProductRepository(context: modelContext).fetchById(id: productID) {
            return product.name
        }
        return "Item"
    }

    // MARK: - Actions

    private func addItem(nominal: Double, deskripsi: String) {
        let item = OrderItem(quantity: 1, price: nominal, deskripsi: deskripsi)
        _ = try? repository.addItem(orderID: order.id, item: item)
    }

    private func duplicateItem(_ item: OrderItem) {
        let copy = OrderItem(
            productID: item.productID,
            quantity: item.quantity,
            price: item.price,
            deskripsi: item.deskripsi
        )
        _ = try? repository.addItem(orderID: order.id, item: copy)
    }

    private func removeItem(_ item: OrderItem) {
        do {
            _ = try repository.removeItem(orderID: order.id, itemID: item.id)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func updateItem(_ item: OrderItem, quantity: Int) {
        do {
            _ = try repository.updateItem(orderID: order.id, itemID: item.id, quantity: quantity)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func updateStatusPo(_ newValue: String?) {
        guard let newValue = newValue else { return }
        do {
            _ = try repository.updateStatusPo(orderID: order.id, to: newValue)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func clearStatusPo() {
        do {
            _ = try repository.clearStatusPo(orderID: order.id)
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

/// Ubah kuantitas satu item (Figma flow "Langsung - Ubah" level item).
struct EditOrderItemView: View {
    @Environment(\.dismiss) private var dismiss

    let item: OrderItem
    let onSave: (Int) -> Void

    @State private var quantity: Int = 1

    var body: some View {
        NavigationView {
            Form {
                Stepper(value: $quantity, in: 1...999) {
                    HStack {
                        Text("Kuantitas")
                        Spacer()
                        Text("\(quantity)").bold()
                    }
                }
            }
            .navigationTitle("Ubah Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        onSave(quantity)
                        dismiss()
                    }
                }
            }
            .onAppear { quantity = item.quantity }
        }
    }
}
