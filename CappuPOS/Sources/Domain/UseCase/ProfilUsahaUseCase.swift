import Foundation
import SwiftData

/// Ambil profil usaha (FR-10.1). Fetch-or-create row singleton — selalu ada
/// hasil, tidak pernah nil (StoreRepository menjamin ini).
public final class FetchProfilUsahaUseCase {
    private let storeRepository: StoreRepository

    public init(storeRepository: StoreRepository) {
        self.storeRepository = storeRepository
    }

    public func execute() throws -> Store {
        try storeRepository.fetchOrCreate()
    }
}

/// Simpan perubahan profil usaha (FR-10.1): nama, logo, kategori, deskripsi,
/// alamat, telepon. Validasi wajib (nama/alamat non-empty) di `StoreRepository`.
public final class SimpanProfilUsahaUseCase {
    private let storeRepository: StoreRepository

    public init(storeRepository: StoreRepository) {
        self.storeRepository = storeRepository
    }

    public func execute(
        nama: String,
        logo: String?,
        kategoriUsaha: String?,
        deskripsi: String?,
        alamat: String,
        telepon: String?
    ) throws -> Store {
        try storeRepository.update(
            nama: nama,
            logo: logo,
            kategoriUsaha: kategoriUsaha,
            deskripsi: deskripsi,
            alamat: alamat,
            telepon: telepon
        )
    }
}
