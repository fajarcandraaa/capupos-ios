import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var categories: [Category]
    @Binding var selected: Category?

    @State private var showingNewCategory = false
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    Button {
                        selected = category
                        dismiss()
                    } label: {
                        HStack {
                            Text(category.name)
                                .foregroundColor(.cappuTextPrimary)
                            Spacer()
                            if selected?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cappuPrimary)
                            }
                        }
                    }
                }

                Button {
                    showingNewCategory = true
                } label: {
                    Label("Tambah kategori baru", systemImage: "plus")
                        .foregroundColor(.cappuPrimary)
                }
            }
            .navigationTitle("Pilih Kategori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewCategory) {
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Button("Batal") { showingNewCategory = false }
                            .buttonStyle(.plain)
                        Spacer()
                        Text("Tambah kategori")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.cappuTextPrimary)
                        Spacer()
                        Button("Simpan") {
                            let repo = CategoryRepository(context: modelContext)
                            if let cat = repo.create(name: newName, description: newDescription.isEmpty ? nil : newDescription) {
                                selected = cat
                                newName = ""
                                newDescription = ""
                                showingNewCategory = false
                            } else {
                                alertMessage = "Kategori dengan nama ini sudah ada atau nama kosong"
                                showingAlert = true
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.cappuPrimary)
                        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)

                    ScrollView {
                        VStack(spacing: 20) {
                            CappuTextField(label: "Nama kategori", placeholder: "Nama kategori", text: $newName)
                            CappuTextArea(label: "Deskripsi", placeholder: "Deskripsi", text: $newDescription)
                        }
                        .padding(20)
                    }
                }
                .background(Color.white)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
