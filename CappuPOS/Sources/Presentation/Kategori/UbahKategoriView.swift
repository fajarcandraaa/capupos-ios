import SwiftUI
import SwiftData

public struct UbahKategoriView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let category: Category

    @State private var nama: String
    @State private var deskripsi: String
    @State private var showError = false
    @State private var errorMessage = ""

    public init(category: Category) {
        self.category = category
        _nama = State(initialValue: category.name)
        _deskripsi = State(initialValue: category.details ?? "")
    }

    private var canSave: Bool {
        !nama.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CappuTextField(label: "Nama Kategori", placeholder: "Nama kategori", text: $nama)
                    CappuTextArea(label: "Deskripsi", placeholder: "Deskripsi (opsional)", text: $deskripsi)
                    Button(action: simpan) {
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
        .alert("Error", isPresented: $showError) {
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
            Text("Ubah Kategori")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func simpan() {
        guard canSave else { return }
        let useCase = UbahKategoriUseCase(categoryRepository: CategoryRepository(context: modelContext))
        if let _ = useCase.execute(id: category.id, name: nama, description: deskripsi.isEmpty ? nil : deskripsi) {
            dismiss()
        } else {
            errorMessage = "Gagal menyimpan kategori atau nama sudah ada"
            showError = true
        }
    }
}
