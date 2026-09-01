import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Design tokens (Figma: Cappu-POS design system)

extension Color {
    /// Primary brand blue — buttons, links. Figma rgb(10,102,178).
    static let cappuPrimary = Color(red: 10.0 / 255, green: 102.0 / 255, blue: 178.0 / 255)
    /// Primary text. Figma rgb(16,24,40).
    static let cappuTextPrimary = Color(red: 16.0 / 255, green: 24.0 / 255, blue: 40.0 / 255)
    /// Secondary text. Figma rgb(71,85,105).
    static let cappuTextSecondary = Color(red: 71.0 / 255, green: 85.0 / 255, blue: 105.0 / 255)
    /// Muted / placeholder text. Figma rgb(100,116,139).
    static let cappuMuted = Color(red: 100.0 / 255, green: 116.0 / 255, blue: 139.0 / 255)
    /// Disabled state. Figma rgb(148,163,184).
    static let cappuDisabled = Color(red: 148.0 / 255, green: 163.0 / 255, blue: 184.0 / 255)
    /// Light panel background. Figma rgb(241,244,248).
    static let cappuPanel = Color(red: 241.0 / 255, green: 244.0 / 255, blue: 248.0 / 255)
    /// Field border. Figma rgb(226,232,240).
    static let cappuBorder = Color(red: 226.0 / 255, green: 232.0 / 255, blue: 240.0 / 255)
}

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
        VStack(spacing: 20) {
            Spacer()

            EmptyProductIllustration()
                .frame(width: 180, height: 180)
                .accessibilityLabel("Ilustrasi produk kosong")
                .accessibilityAddTraits(.isImage)

            VStack(spacing: 4) {
                Text("Produk belum tersedia")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cappuTextPrimary)

                Text("Anda belum melakukan pengelolaan data produk. Silahkan tambahkan sekarang.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.cappuTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                if #available(iOS 17.0, *) {
                    showAddProduct = true
                } else {
                    unavailable = true
                }
            } label: {
                Text("Tambah produk")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.cappuPrimary)
                    .cornerRadius(24)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: 240)
        .frame(maxWidth: .infinity)
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

// MARK: - Empty state illustration (reconstructed from Figma vectors)

struct EmptyProductIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cappuPanel)
                .frame(width: 150, height: 128)

            HStack(alignment: .bottom, spacing: 12) {
                ProductPackage(color: .cappuMuted)
                ProductPackage(color: .cappuDisabled)
            }
        }
    }
}

struct ProductPackage: View {
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 42, height: 36)
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.85))
                .frame(width: 42, height: 72)
        }
    }
}

// MARK: - Add product form (Figma: "Tambah produk")

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

    private var trimmedName: String {
        productName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    photoField

                    CappuTextField(label: "Nama", placeholder: "Nama", text: $productName)
                    CappuTextField(label: "Harga", placeholder: "Harga", text: $productPrice, numberPad: true)

                    CappuCategoryField(
                        label: "Kategori",
                        selected: selectedCategory,
                        onTap: { showingNewCategoryForm = true },
                        onClear: { selectedCategory = nil }
                    )

                    CappuTextArea(label: "Informasi tambahan", placeholder: "Informasi tambahan", text: $productDescription)

                    Button {
                        save()
                    } label: {
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
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingNewCategoryForm) {
            NewCategoryForm(
                name: $newCategoryName,
                description: $newCategoryDescription,
                onSave: { name, description in
                    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        alertMessage = "Nama kategori harus diisi"
                        showingAlert = true
                        return
                    }
                    onNewCategory(name, description.isEmpty ? nil : description)
                    showingNewCategoryForm = false
                },
                onClose: { showingNewCategoryForm = false }
            )
        }
        #if os(iOS)
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(imageData: $productImage)
        }
        #endif
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.cappuTextPrimary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Text("Tambah produk")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var photoField: some View {
        Button {
            #if os(iOS)
            showingImagePicker = true
            #endif
        } label: {
            Group {
                if let image = productImage {
                    DeserializedImage(data: image)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.cappuBorder, lineWidth: 1)
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func save() {
        guard !trimmedName.isEmpty else {
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
            name: trimmedName,
            price: price,
            categoryID: selectedCategory?.id,
            image: productImage,
            productDescription: productDescription.isEmpty ? nil : productDescription
        )
        onSave(product)
        onClose()
    }
}

// MARK: - Form field components (Figma: radius 2, padding 16/10)

struct CappuFieldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(.cappuMuted)
    }
}

struct CappuFieldContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.cappuBorder, lineWidth: 1)
            )
    }
}

struct CappuTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var numberPad = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CappuFieldLabel(text: label)
            CappuFieldContainer {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.cappuTextPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    #if os(iOS)
                    .keyboardType(numberPad ? .numberPad : .default)
                    #endif
            }
        }
    }
}

struct CappuTextArea: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CappuFieldLabel(text: label)
            CappuFieldContainer {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.cappuMuted)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.cappuTextPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                }
                .frame(height: 80)
            }
        }
    }
}

struct CappuCategoryField: View {
    let label: String
    let selected: Category?
    let onTap: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CappuFieldLabel(text: label)
            CappuFieldContainer {
                HStack(spacing: 8) {
                    Text(selected?.name ?? "Kategori")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(selected == nil ? .cappuMuted : .cappuTextPrimary)
                        .onTapGesture(perform: onTap)
                    Spacer()
                    if selected != nil {
                        Button(action: onClear) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.cappuMuted)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.cappuMuted)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
            }
        }
    }
}

// MARK: - New category form (Figma: "Tambah kategori")

private struct NewCategoryForm: View {
    @Binding var name: String
    @Binding var description: String
    let onSave: (String, String) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.cappuTextPrimary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Text("Tambah kategori")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.cappuTextPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 56)

            ScrollView {
                VStack(spacing: 20) {
                    CappuTextField(label: "Nama kategori", placeholder: "Nama kategori", text: $name)
                    CappuTextArea(label: "Deskripsi", placeholder: "Deskripsi", text: $description)

                    Button {
                        onSave(name, description)
                    } label: {
                        Text("Simpan")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.cappuDisabled
                                    : Color.cappuPrimary
                            )
                            .cornerRadius(24)
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(Color.white)
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
