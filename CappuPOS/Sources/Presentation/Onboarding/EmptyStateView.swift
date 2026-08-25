import SwiftUI
import SwiftData

public struct EmptyStateView: View {
    @State private var showAddProduct = false
    @State private var productName = ""
    @State private var productPrice = ""
    @State private var productDescription = ""
    @State private var selectedCategory: Category?
    @State private var newCategoryName = ""
    @State private var newCategoryDescription = ""
    @State private var showingNewCategoryForm = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    let onClose: () -> Void
    @Environment(\.modelContext) private var modelContext

    public init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "barcode")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Belum ada produk")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tambahkan produk pertama Anda untuk mulai menjual")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Tambah Produk Pertama") {
                showAddProduct = true
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showAddProduct) {
            AddProductForm(
                productName: $productName,
                productPrice: $productPrice,
                productDescription: $productDescription,
                selectedCategory: $selectedCategory,
                onSave: { product in
                    let repo = ProductRepository(context: modelContext)
                    try? repo.add(
                        name: product.name,
                        price: product.price,
                        description: product.productDescription,
                        categoryID: product.categoryID,
                        imageData: product.image
                    )
                    onClose()
                },
                onNewCategory: { name, description in
                    let repo = CategoryRepository(context: modelContext)
                    selectedCategory = repo.create(name: name, description: description)
                }
            )
        }
    }
}

struct AddProductForm: View {
    @Binding var productName: String
    @Binding var productPrice: String
    @Binding var productDescription: String
    @Binding var selectedCategory: Category?

    let onSave: (Product) -> Void
    let onNewCategory: (String, String?) -> Void

    @State private var newCategoryName = ""
    @State private var newCategoryDescription = ""
    @State private var showingNewCategoryForm = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informasi Produk")) {
                    TextField("Nama Produk", text: $productName)
                    TextField("Harga", text: $productPrice)
                    TextField("Deskripsi", text: $productDescription)
                }

                Section(header: Text("Kategori")) {
                    if let category = selectedCategory {
                        HStack {
                            Text(category.name)
                            Spacer()
                            Button {
                                selectedCategory = nil
                            } label: {
                                Image(systemName: "xmark.circle")
                            }
                        }
                    } else {
                        Button("Pilih / Tambah Kategori") {
                            showingNewCategoryForm = true
                        }
                    }
                }
            }
            .navigationTitle("Tambah Produk")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        guard !productName.isEmpty else {
                            alertMessage = "Nama produk harus diisi"
                            showingAlert = true
                            return
                        }
                        guard let price = Double(productPrice), price > 0 else {
                            alertMessage = "Harga harus berupa angka positif"
                            showingAlert = true
                            return
                        }
                        let product = Product(
                            name: productName,
                            price: price,
                            categoryID: selectedCategory?.id,
                            productDescription: productDescription.isEmpty ? nil : productDescription
                        )
                        onSave(product)
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingNewCategoryForm) {
                NavigationView {
                    Form {
                        TextField("Nama Kategori", text: $newCategoryName)
                        TextField("Deskripsi", text: $newCategoryDescription)
                    }
                    .navigationTitle("Kategori Baru")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Simpan") {
                                guard !newCategoryName.isEmpty else {
                                    alertMessage = "Nama kategori harus diisi"
                                    showingAlert = true
                                    return
                                }
                                onNewCategory(newCategoryName, newCategoryDescription.isEmpty ? nil : newCategoryDescription)
                                showingNewCategoryForm = false
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Batal") {
                                showingNewCategoryForm = false
                            }
                        }
                    }
                }
            }
        }
    }
}