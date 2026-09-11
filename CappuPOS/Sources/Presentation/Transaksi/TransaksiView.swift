import SwiftUI
import SwiftData

/// Item draft di keranjang (belum dipersist). Produk (dari kategori/search) atau manual.
struct CartItem: Identifiable {
    let id = UUID()
    let productID: UUID?
    let name: String
    var quantity: Int
    var price: Double
    var deskripsi: String? = nil

    var subtotal: Double { price * Double(quantity) }

    func toOrderItem() -> OrderItem {
        OrderItem(
            productID: productID,
            quantity: quantity,
            price: price,
            deskripsi: deskripsi?.isEmpty == true ? nil : deskripsi
        )
    }
}

/// Entry layar Transaksi (FR-04 / FR-05): pilih produk by kategori/search + qty,
/// item manual, mode PO opsional, simpan sebagai Open Bill "Belum Bayar".
public struct TransaksiView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Product> { $0.isDeleted == false })
    private var products: [Product]

    @Query private var categories: [Category]

    @State private var cart: [CartItem] = []
    @State private var selectedCategoryID: UUID?
    @State private var searchText = ""
    @State private var statusPo: String? = nil
    @State private var showingManualItem = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    public init() {}

    private var sortedCategories: [Category] {
        categories.sorted { $0.order < $1.order }
    }

    private var filteredProducts: [Product] {
        var result = products
        if let selectedCategoryID = selectedCategoryID {
            result = result.filter { $0.categoryID == selectedCategoryID }
        }
        if !searchText.isEmpty {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }
        return result
    }

    private var grandTotal: Double {
        cart.reduce(0.0) { $0 + $1.subtotal }
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            categoryTabs
            productGrid
            cartSection
        }
        .background(Color.white)
        .sheet(isPresented: $showingManualItem) {
            TransaksiManualItemView { nominal, deskripsi in
                cart.append(
                    CartItem(productID: nil, name: deskripsi, quantity: 1, price: nominal, deskripsi: deskripsi)
                )
            }
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

            Text("Transaksi")
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
            TextField("Cari produk", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.cappuTextPrimary)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Color.cappuPanel)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "Semua", isSelected: selectedCategoryID == nil) {
                    selectedCategoryID = nil
                }
                ForEach(sortedCategories) { category in
                    categoryChip(title: category.name, isSelected: selectedCategoryID == category.id) {
                        selectedCategoryID = category.id
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }

    private func categoryChip(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .cappuTextSecondary)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(isSelected ? Color.cappuPrimary : Color.cappuPanel)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(filteredProducts) { product in
                    Button {
                        addToCart(product: product)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.cappuTextPrimary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            Text(PriceFormatter.format(product.price))
                                .font(.system(size: 12))
                                .foregroundColor(.cappuPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.cappuPanel)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private var cartSection: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(cart) { item in
                        cartRow(item)
                    }
                }
            }
            .frame(maxHeight: 160)

            HStack(spacing: 8) {
                Button {
                    showingManualItem = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Item Manual")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.cappuPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.cappuPrimary, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .font(.system(size: 11))
                        .foregroundColor(.cappuMuted)
                    Text(PriceFormatter.format(grandTotal))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.cappuTextPrimary)
                }
            }
            .padding(.horizontal, 16)

            poPicker

            Button {
                saveOpenBill()
            } label: {
                Text("Simpan / Open Bill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(cart.isEmpty ? Color.cappuDisabled : Color.cappuPrimary)
                    .cornerRadius(24)
            }
            .buttonStyle(.plain)
            .disabled(cart.isEmpty)
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var poPicker: some View {
        HStack(spacing: 8) {
            Text("Mode PO (opsional)")
                .font(.system(size: 13))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
            Picker("", selection: Binding(
                get: { statusPo ?? "" },
                set: { newValue in
                    statusPo = newValue.isEmpty ? nil : newValue
                }
            )) {
                Text("Bukan PO").tag("")
                ForEach(StatusPO.allCasesInOrder, id: \.self) { value in
                    Text(poLabel(value)).tag(value)
                }
            }
            .labelsHidden()
        }
        .padding(.horizontal, 16)
    }

    private func cartRow(_ item: CartItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.cappuTextPrimary)
                    .lineLimit(1)
                Text(PriceFormatter.format(item.price))
                    .font(.system(size: 11))
                    .foregroundColor(.cappuMuted)
            }
            Spacer()

            // Pengaturan kuantitas (AC)
            Button {
                decrement(item)
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundColor(.cappuPrimary)
            }
            .buttonStyle(.plain)

            Text("\(item.quantity)")
                .font(.system(size: 13, weight: .bold))
                .frame(minWidth: 20)

            Button {
                increment(item)
            } label: {
                Image(systemName: "plus.circle")
                    .foregroundColor(.cappuPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.cappuPanel)
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func addToCart(product: Product) {
        if let index = cart.firstIndex(where: { $0.productID == product.id }) {
            cart[index].quantity += 1
        } else {
            cart.append(
                CartItem(productID: product.id, name: product.name, quantity: 1, price: product.price)
            )
        }
    }

    private func increment(_ item: CartItem) {
        guard let index = cart.firstIndex(where: { $0.id == item.id }) else { return }
        cart[index].quantity += 1
    }

    private func decrement(_ item: CartItem) {
        guard let index = cart.firstIndex(where: { $0.id == item.id }) else { return }
        if cart[index].quantity > 1 {
            cart[index].quantity -= 1
        } else {
            cart.remove(at: index)
        }
    }

    private func saveOpenBill() {
        let items = cart.map { $0.toOrderItem() }
        let repository = OrderRepository(context: modelContext)
        let useCase = SimpanTransaksiUseCase(orderRepository: repository)
        do {
            _ = try useCase.execute(items: items, statusPo: statusPo, catatan: nil)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    /// Nilai tersimpan snake_case; label UI boleh nama tampilan (FR-05).
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
