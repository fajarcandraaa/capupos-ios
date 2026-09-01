import SwiftUI
import SwiftData

public struct ArurKetersediaanStokView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let product: Product

    @State private var trackStok: Bool
    @State private var jumlahStok: String
    @State private var stokMinimal: String
    @State private var showingAlert = false
    @State private var alertMessage = ""

    public init(product: Product) {
        self.product = product
        _trackStok = State(initialValue: product.stockTracked)
        _jumlahStok = State(initialValue: String(product.stockQuantity ?? 0))
        _stokMinimal = State(initialValue: String(product.stockMinimal ?? 0))
    }

    private var canSave: Bool {
        !trackStok || (
            !jumlahStok.isEmpty && !stokMinimal.isEmpty &&
            Int(jumlahStok) ?? 0 >= 0 &&
            Int(stokMinimal) ?? 0 >= 0
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Lacak Ketersediaan Stok")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cappuTextPrimary)
                        Toggle("Aktifkan pelacakan stok", isOn: $trackStok)
                            .font(.system(size: 14))
                            .foregroundColor(.cappuTextPrimary)
                    }

                    if trackStok {
                        VStack(alignment: .leading, spacing: 20) {
                            CappuTextField(
                                label: "Jumlah Stok",
                                placeholder: "0",
                                text: $jumlahStok,
                                numberPad: true
                            )
                            CappuTextField(
                                label: "Stok Minimal",
                                placeholder: "0",
                                text: $stokMinimal,
                                numberPad: true
                            )
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Info")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.cappuTextPrimary)
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(.cappuPrimary)
                                    Text("Notifikasi akan muncul saat stok mencapai atau di bawah batas minimal.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.cappuTextSecondary)
                                }
                            }
                        }
                    }

                    Button(action: save) {
                        Text("Simpan")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(canSave ? Color.cappuPrimary : Color.cappuDisabled)
                            .cornerRadius(24)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
                .padding(20)
            }
        }
        .background(Color.white)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
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
            Text("Atur ketersediaan stok")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func save() {
        guard canSave else {
            alertMessage = "Periksa kembali input stok"
            showingAlert = true
            return
        }

        product.stockTracked = trackStok
        if trackStok {
            product.stockQuantity = Int(jumlahStok) ?? 0
            product.stockMinimal = Int(stokMinimal) ?? 0
        }
        product.updatedAt = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "Gagal menyimpan: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
