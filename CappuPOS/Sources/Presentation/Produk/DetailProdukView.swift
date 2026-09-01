import SwiftUI
import SwiftData

public struct DetailProdukView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var categories: [Category]
    let product: Product

    @State private var showingUbah = false
    @State private var showingArurStok = false
    @State private var showingHapusKonfirmasi = false
    @State private var showingError = false
    @State private var errorMessage = ""

    public init(product: Product) {
        self.product = product
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    infoSection
                    stockButton
                    actionButtons
                }
                .padding(20)
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showingUbah) {
            UbahProdukView(product: product)
        }
        .sheet(isPresented: $showingArurStok) {
            ArurKetersediaanStokView(product: product)
        }
        .alert("Hapus produk?", isPresented: $showingHapusKonfirmasi) {
            Button("Batal", role: .cancel) {}
            Button("Hapus", role: .destructive) { hapus() }
        } message: {
            Text("Produk \"\(product.name)\" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.")
        }
        .alert("Gagal menghapus", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
            Text("Detail produk")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
            Button(action: { showingUbah = true }) {
                Text("Ubah")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cappuPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var imageSection: some View {
        Group {
            if let imageData = product.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    Color.cappuPanel
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.cappuDisabled)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailRow(label: "Nama", value: product.name)
            DetailRow(label: "Kategori", value: categoryName)
            DetailRow(label: "Harga", value: PriceFormatter.format(product.price))
            DetailRow(label: "Deskripsi", value: product.productDescription ?? "-")
            DetailRow(label: "Lacak Stok", value: product.stockTracked ? "Ya" : "Tidak")
            if product.stockTracked {
                DetailRow(label: "Stok", value: "\(product.stockQuantity ?? 0) (min: \(product.stockMinimal ?? 0))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cappuPanel)
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showingUbah = true }) {
                Text("Ubah")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.cappuPrimary)
                    .cornerRadius(24)
            }
            .buttonStyle(.plain)

            Button(action: { showingHapusKonfirmasi = true }) {
                Text("Hapus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.red, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var stockButton: some View {
        Button(action: { showingArurStok = true }) {
            Text("Atur Ketersediaan Stok")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.cappuPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.cappuPanel)
                .cornerRadius(24)
        }
        .buttonStyle(.plain)
    }

    private var categoryName: String {
        categories.first(where: { $0.id == product.categoryID })?.name ?? "Tanpa kategori"
    }

    private func hapus() {
        let useCase = HapusProdukUseCase(productRepository: ProductRepository(context: modelContext))
        do {
            try useCase.execute(id: product.id)
            dismiss()
        } catch {
            errorMessage = "Gagal menghapus produk: \(error.localizedDescription)"
            showingError = true
        }
    }

}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.cappuMuted)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.cappuTextPrimary)
        }
    }
}
