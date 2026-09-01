import SwiftUI
import SwiftData

public struct UbahProdukView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var categories: [Category]
    let product: Product

    @State private var productName: String
    @State private var productPrice: String
    @State private var productDescription: String
    @State private var productImage: Data?
    @State private var selectedCategory: Category?
    @State private var clearImage = false
    @State private var showingImagePicker = false
    @State private var showingCategoryPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    public init(product: Product) {
        self.product = product
        _productName = State(initialValue: product.name)
        _productPrice = State(initialValue: String(Int(product.price)))
        _productDescription = State(initialValue: product.productDescription ?? "")
        _productImage = State(initialValue: product.image)
    }

    private var canSave: Bool {
        !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !productPrice.isEmpty &&
        Double(productPrice) ?? 0 > 0
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 20) {
                    photoField
                    CappuTextField(label: "Nama", placeholder: "Nama produk", text: $productName)
                    CappuTextField(label: "Harga", placeholder: "0", text: $productPrice, numberPad: true)
                    CappuCategoryField(label: "Kategori", selected: selectedCategory, onTap: { showingCategoryPicker = true }, onClear: { selectedCategory = nil })
                    CappuTextArea(label: "Deskripsi", placeholder: "Deskripsi produk (opsional)", text: $productDescription)
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
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(Color.white)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        #if os(iOS)
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(imageData: $productImage)
        }
        #endif
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selected: $selectedCategory)
        }
        .onAppear {
            if selectedCategory == nil, let categoryID = product.categoryID {
                selectedCategory = categories.first(where: { $0.id == categoryID })
            }
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
            Text("Ubah produk")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var photoField: some View {
        VStack(spacing: 8) {
            Button {
                #if os(iOS)
                showingImagePicker = true
                #endif
            } label: {
                Group {
                    if let image = productImage, let uiImage = UIImage(data: image) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.cappuPrimary)
                            Text("Tambah Foto")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.cappuPrimary)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cappuBorder, lineWidth: 1))
                    }
                }
            }
            .buttonStyle(.plain)

            if productImage != nil {
                Button {
                    productImage = nil
                    clearImage = true
                } label: {
                    Text("Hapus foto")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        guard !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Nama produk harus diisi"
            showingAlert = true
            return
        }
        guard let price = Double(productPrice), price > 0 else {
            alertMessage = "Harga harus berupa angka positif"
            showingAlert = true
            return
        }

        let useCase = UbahProdukUseCase(productRepository: ProductRepository(context: modelContext))
        do {
            _ = try useCase.execute(
                id: product.id,
                nama: productName,
                harga: price,
                kategoriID: selectedCategory?.id,
                deskripsi: productDescription.isEmpty ? nil : productDescription,
                imageData: productImage,
                clearImage: clearImage
            )
            dismiss()
        } catch {
            alertMessage = "Gagal mengubah produk: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
