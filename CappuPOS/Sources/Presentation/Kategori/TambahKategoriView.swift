import SwiftUI
import SwiftData

public struct TambahKategoriView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var nama = ""
    @State private var deskripsi = ""
    @State private var showError = false
    @State private var errorMessage = ""

    private var canSave: Bool {
        !nama.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init() {}

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
            Text("Tambah Kategori")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func simpan() {
        guard canSave else { return }
        let useCase = TambahKategoriUseCase(categoryRepository: CategoryRepository(context: modelContext))
        if let _ = useCase.execute(name: nama, description: deskripsi.isEmpty ? nil : deskripsi) {
            dismiss()
        } else {
            errorMessage = "Kategori dengan nama ini sudah ada atau nama kosong"
            showError = true
        }
    }
}
