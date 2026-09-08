import SwiftUI
import SwiftData

public struct KategoriListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.order) private var categories: [Category]

    @State private var showingTambah = false
    @State private var selectedForEdit: Category?
    @State private var selectedForDelete: Category?
    @State private var affectedProductCount = 0
    @State private var showDeleteConfirm = false
    @State private var showError = false
    @State private var errorMessage = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            if categories.isEmpty {
                emptyState
            } else {
                categoryListContent
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showingTambah) {
            TambahKategoriView()
        }
        .sheet(item: $selectedForEdit) { category in
            UbahKategoriView(category: category)
        }
        .alert("Hapus kategori?", isPresented: $showDeleteConfirm) {
            Button("Batal", role: .cancel) {}
            Button("Hapus", role: .destructive) { hapusKategori() }
        } message: {
            Text("\(affectedProductCount) produk akan jadi \"Tanpa Kategori\". Tindakan ini tidak dapat dibatalkan.")
        }
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
            Text("Kelola Kategori")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
            Button(action: { showingTambah = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.cappuPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundColor(.cappuDisabled)
            Text("Belum ada kategori")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Text("Tambahkan kategori pertama Anda untuk mengorganisir produk.")
                .font(.system(size: 12))
                .foregroundColor(.cappuTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var categoryListContent: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(filteredCategories.enumerated()), id: \.element.id) { index, category in
                    CategoryRow(
                        category: category,
                        canMoveUp: index > 0,
                        canMoveDown: index < filteredCategories.count - 1,
                        onMoveUp: { moveCategory(at: index, to: index - 1) },
                        onMoveDown: { moveCategory(at: index, to: index + 1) },
                        onEdit: { selectedForEdit = category },
                        onDelete: {
                            selectedForDelete = category
                            loadAffectedCount(categoryID: category.id)
                        }
                    )
                }
            }
            .padding(16)
        }
    }

    private var filteredCategories: [Category] {
        categories
    }

    private func loadAffectedCount(categoryID: UUID) {
        let useCase = HapusKategoriUseCase(categoryRepository: CategoryRepository(context: modelContext))
        do {
            affectedProductCount = try useCase.countAffectedProducts(categoryID: categoryID)
            showDeleteConfirm = true
        } catch {
            errorMessage = "Gagal memuat data produk: \(error.localizedDescription)"
            showError = true
        }
    }

    private func hapusKategori() {
        guard let category = selectedForDelete else { return }
        let useCase = HapusKategoriUseCase(categoryRepository: CategoryRepository(context: modelContext))
        let success = useCase.execute(id: category.id)
        if !success {
            errorMessage = "Gagal menghapus kategori"
            showError = true
        }
        selectedForDelete = nil
    }

    private func moveCategory(at sourceIndex: Int, to destinationIndex: Int) {
        var ordered = filteredCategories
        let moved = ordered.remove(at: sourceIndex)
        ordered.insert(moved, at: destinationIndex)

        let useCase = ReorderKategoriUseCase(categoryRepository: CategoryRepository(context: modelContext))
        let success = useCase.execute(categoryIDs: ordered.map(\.id))
        if !success {
            errorMessage = "Gagal mengubah urutan kategori"
            showError = true
        }
    }
}

private struct CategoryRow: View {
    let category: Category
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cappuTextPrimary)
                if let details = category.details, !details.isEmpty {
                    Text(details)
                        .font(.system(size: 12))
                        .foregroundColor(.cappuTextSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if canMoveUp {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14))
                        .foregroundColor(.cappuPrimary)
                }
                .buttonStyle(.plain)
            }
            if canMoveDown {
                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.cappuPrimary)
                }
                .buttonStyle(.plain)
            }
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.cappuPrimary)
            }
            .buttonStyle(.plain)
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.cappuPanel)
        .cornerRadius(8)
    }
}
