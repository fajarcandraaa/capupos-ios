import SwiftUI
import SwiftData

public struct ListProdukView: View {
    @Query(filter: #Predicate<Product> { $0.isDeleted == false })
    private var products: [Product]

    @Query private var categories: [Category]

    @State private var selectedCategoryID: UUID?
    @State private var searchText = ""
    @State private var showingTambahProduk = false
    @State private var showingDetailProduct: Product?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            categoryTabs
            productGrid
        }
        .background(Color.white)
        .sheet(isPresented: $showingTambahProduk) {
            TambahProdukView()
        }
        .sheet(item: $showingDetailProduct) { product in
            DetailProdukView(product: product)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text("Kelola Produk")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
            Button {
                showingTambahProduk = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.cappuPrimary)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
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
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.cappuMuted)
                }
                .buttonStyle(.plain)
            }
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
                CategoryTabChip(
                    title: "Semua",
                    isSelected: selectedCategoryID == nil,
                    onTap: { selectedCategoryID = nil }
                )
                ForEach(categories) { category in
                    CategoryTabChip(
                        title: category.name,
                        isSelected: selectedCategoryID == category.id,
                        onTap: { selectedCategoryID = category.id }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }

    private var filteredProducts: [Product] {
        var result = products
        if let selectedCategoryID = selectedCategoryID {
            result = result.filter { $0.categoryID == selectedCategoryID }
        }
        if !searchText.isEmpty {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            result = result.filter { product in
                product.name.lowercased().contains(query) ||
                (product.productDescription?.lowercased().contains(query) ?? false)
            }
        }
        return result
    }

    private var productGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return ScrollView {
            if filteredProducts.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 60)
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundColor(.cappuDisabled)
                    Text("Produk tidak ditemukan")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cappuTextPrimary)
                    Text("Coba ubah kata kunci pencarian atau tambah produk baru.")
                        .font(.system(size: 12))
                        .foregroundColor(.cappuTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredProducts) { product in
                        ProductCard(product: product, categoryName: categoryName(for: product)) {
                            showingDetailProduct = product
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func categoryName(for product: Product) -> String {
        categories.first(where: { $0.id == product.categoryID })?.name ?? "Tanpa kategori"
    }
}

private struct CategoryTabChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
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
}

private struct ProductCard: View {
    let product: Product
    let categoryName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Group {
                    if let imageData = product.image, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Color.cappuPanel
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.cappuDisabled)
                        }
                    }
                }
                .frame(height: 96)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cappuTextPrimary)
                        .lineLimit(1)
                    Text(categoryName)
                        .font(.system(size: 11))
                        .foregroundColor(.cappuMuted)
                        .lineLimit(1)
                    Text(formatPrice(product.price))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cappuPrimary)
                }
            }
            .padding(8)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.cappuBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp\(Int(value))"
    }
}
