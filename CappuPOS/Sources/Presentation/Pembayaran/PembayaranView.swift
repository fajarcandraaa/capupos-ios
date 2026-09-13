import SwiftUI
import SwiftData

/// Form pembayaran (TASK-006 FR-06.1 / FR-06.2): pilih metode tunai/non-tunai,
/// input nominal diterima (tunai → auto kembalian), optional catatan.
struct PembayaranView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let order: Order

    @State private var metodeBayar = MetodeBayar.tunai
    @State private var nominalDiterima: String = ""
    @State private var catatan: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var kembalian: Double {
        guard let nominal = Double(nominalDiterima) else { return 0 }
        return nominal - order.subtotal
    }

    var canConfirm: Bool {
        if metodeBayar == MetodeBayar.tunai {
            return !nominalDiterima.isEmpty && Double(nominalDiterima) ?? 0 >= order.subtotal
        }
        return true
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Pesanan") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total")
                            .font(.system(size: 12))
                            .foregroundColor(.cappuMuted)
                        Text(PriceFormatter.format(order.subtotal))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.cappuTextPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section("Metode Pembayaran") {
                    Picker("", selection: $metodeBayar) {
                        Text("Tunai").tag(MetodeBayar.tunai)
                        Text("Non-Tunai").tag(MetodeBayar.nonTunai)
                    }
                    .labelsHidden()
                }

                if metodeBayar == MetodeBayar.tunai {
                    Section {
                        HStack {
                            Text("Nominal Diterima")
                            Spacer()
                            TextField("0", text: $nominalDiterima)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 150)
                        }
                        if !nominalDiterima.isEmpty, let nominal = Double(nominalDiterima), nominal >= order.subtotal {
                            HStack {
                                Text("Kembalian")
                                    .foregroundColor(.cappuMuted)
                                Spacer()
                                Text(PriceFormatter.format(kembalian))
                                    .foregroundColor(.cappuPrimary)
                                    .bold()
                            }
                        }
                    } header: {
                        Text("Uang Masuk")
                    }
                }

                Section("Catatan (Opsional)") {
                    TextField("Tambahan informasi", text: $catatan)
                }
            }
            .navigationTitle("Pembayaran")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bayar") {
                        bayar()
                    }
                    .disabled(!canConfirm)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func bayar() {
        let useCase = BayarTransaksiUseCase(
            orderRepository: OrderRepository(context: modelContext),
            productRepository: ProductRepository(context: modelContext)
        )
        let nominal = metodeBayar == MetodeBayar.tunai ? Double(nominalDiterima) : nil
        let ket = catatan.isEmpty ? nil : catatan
        do {
            _ = try useCase.execute(
                orderID: order.id,
                metodeBayar: metodeBayar,
                nominalDiterima: nominal,
                catatan: ket
            )
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}
