import Foundation
import SwiftData

/// Repository singleton `Store` (FR-10, TASK-007). App single-outlet — satu row
/// saja di DB, constraint dijaga di sini via fetch-or-create (DECISIONS.md
/// [2026-09-14] poin 2), bukan unique constraint schema SwiftData.
public final class StoreRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Fetch row Store tunggal, create kosong bila belum ada. Selalu lewat sini —
    /// tidak ada jalur lain insert Store, agar singleton tidak pecah.
    public func fetchOrCreate() throws -> Store {
        let descriptor = FetchDescriptor<Store>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let store = Store()
        context.insert(store)
        try context.save()
        return store
    }

    /// Simpan perubahan profil usaha. `nama` wajib non-empty (FR-10.1); `alamat`
    /// wajib juga — dipakai di header struk (FR-10.2).
    public func update(
        nama: String,
        logo: String?,
        kategoriUsaha: String?,
        deskripsi: String?,
        alamat: String,
        telepon: String?
    ) throws -> Store {
        let trimmedNama = nama.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAlamat = alamat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNama.isEmpty, !trimmedAlamat.isEmpty else {
            throw NSError(
                domain: "StoreRepository", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Nama dan alamat usaha wajib diisi"]
            )
        }
        let store = try fetchOrCreate()
        store.nama = trimmedNama
        store.logo = logo
        store.kategoriUsaha = kategoriUsaha?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : kategoriUsaha?.trimmingCharacters(in: .whitespacesAndNewlines)
        store.deskripsi = deskripsi?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : deskripsi?.trimmingCharacters(in: .whitespacesAndNewlines)
        store.alamat = trimmedAlamat
        store.telepon = telepon?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : telepon?.trimmingCharacters(in: .whitespacesAndNewlines)
        try context.save()
        return store
    }
}
