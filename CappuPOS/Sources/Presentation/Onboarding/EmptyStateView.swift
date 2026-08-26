import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct EmptyStateView: View {
    @State private var showAddProduct = false
    @State private var productName = ""
    @State private var productPrice = ""
    @State private var productDescription = ""
    @State private var productImage: Data? = nil
    @State private var selectedCategory: Category?
    @State private var newCategoryName = ""
    @State private var newCategoryDescription = ""
    @State private var showingNewCategoryForm = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.modelContext) private var modelContext
    @State private var unavailable = false

    let onClose: () -> Void

    public init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Belum ada produk")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tambahkan produk pertama Anda untuk mulai menjual")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Tambah Produk Pertama") {
                if #available(iOS 17.0, *) {
                    showAddProduct = true
                } else {
                    unavailable = true
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .alert("Fitur tidak tersedia", isPresented: $unavailable) {
            Button("OK", role: .cancel) { unavailable = false }
        } message: {
            Text("Penambahan produk membutuhkan iOS 17 atau lebih baru.")
        }
        .sheet(isPresented: $showAddProduct) {
            if #available(iOS 17.0, *) {
                AddProductForm(
                    productName: $productName,
                    productPrice: $productPrice,
                    productDescription: $productDescription,
                    productImage: $productImage,
                    selectedCategory: $selectedCategory,
                    onSave: { product in
                        if #available(iOS 17.0, *) {
                            let repo = ProductRepository(context: modelContext)
                            _ = try? repo.add(
                                name: product.name,
                                price: product.price,
                                description: product.productDescription,
                                categoryID: product.categoryID,
                                imageData: product.image
                            )
                            onClose()
                        } else {
                            alertMessage = "Fitur tidak didukung di versi iOS ini"
                            showingAlert = true
                        }
                    },
                    onNewCategory: { name, description in
                        if #available(iOS 17.0, *) {
                            let repo = CategoryRepository(context: modelContext)
                            selectedCategory = repo.create(name: name, description: description)
                        } else {
                            alertMessage = "Fitur tidak didukung di versi iOS ini"
                            showingAlert = true
                        }
                    },
                    onClose: {
                        showAddProduct = false
                    }
                )
            } else {
                Text("Fitur ini membutuhkan iOS 17 atau lebih baru.")
                    .padding()
            }
        }
    }
}

struct AddProductForm: View {
    @Binding var productName: String
    @Binding var productPrice: String
    @Binding var productDescription: String
    @Binding var productImage: Data?
    @Binding var selectedCategory: Category?

    let onSave: (Product) -> Void
    let onNewCategory: (String, String?) -> Void
    let onClose: () -> Void

    @State private var newCategoryName = ""
    @State private var newCategoryDescription = ""
    @State private var showingNewCategoryForm = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingImagePicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Foto Produk")) {
                    Button("Pilih Foto") {
                        #if os(iOS)
                        showingImagePicker = true
                        #endif
                    }
                    if let image = productImage {
                        DeserializedImage(data: image)
                    }
                }

                Section(header: Text("Informasi Produk")) {
                    TextField("Nama Produk", text: $productName)
                    TextField("Harga", text: $productPrice)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
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
                        onClose()
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
                            image: productImage,
                            productDescription: productDescription.isEmpty ? nil : productDescription
                        )
                        onSave(product)
                        onClose()
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
            #if os(iOS)
            .sheet(isPresented: $showingImagePicker) {
                PhotoPicker(imageData: $productImage)
            }
            #endif
        }
    }
}

struct DeserializedImage: View {
    let data: Data

    var body: some View {
        Group {
            #if os(iOS)
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
            }
            #endif
        }
    }
}

#if os(iOS)
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif
