import Foundation

/// Hasil format struk teks polos (FR-10.2). `teks` siap dicetak/disalin —
/// header usaha + item + total + pembayaran. Dipakai StrukView.
public struct StrukOutput {
    public let teks: String
    public let namaUsaha: String
    public let tanggal: Date

    public init(teks: String, namaUsaha: String, tanggal: Date) {
        self.teks = teks
        self.namaUsaha = namaUsaha
        self.tanggal = tanggal
    }
}

/// Rakit struk teks dari sebuah order lunas (FR-10.2). Tanpa dependency printer
/// eksternal — cukup string monospace. Format angka pakai `PriceFormatter`.
public final class GenerateStrukUseCase {
    private let orderRepository: OrderRepository
    private let productRepository: ProductRepository
    private let storeRepository: StoreRepository

    public init(
        orderRepository: OrderRepository,
        productRepository: ProductRepository,
        storeRepository: StoreRepository
    ) {
        self.orderRepository = orderRepository
        self.productRepository = productRepository
        self.storeRepository = storeRepository
    }

    public func execute(orderID: UUID) throws -> StrukOutput {
        guard let order = try orderRepository.fetchById(id: orderID) else {
            throw NSError(
                domain: "GenerateStrukUseCase", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Order tidak ditemukan"]
            )
        }

        let store = try storeRepository.fetchOrCreate()

        var lines: [String] = []
        let separator = String(repeating: "-", count: 32)

        // Header usaha.
        let namaUsaha = store.nama.isEmpty ? "Toko" : store.nama
        lines.append(namaUsaha)
        if !store.alamat.isEmpty {
            lines.append(store.alamat)
        }
        if let telepon = store.telepon, !telepon.isEmpty {
            lines.append("Telp: \(telepon)")
        }
        lines.append(separator)

        // Item.
        for item in order.items {
            let nama = resolveNamaItem(item)
            let harga = PriceFormatter.format(item.price)
            lines.append("\(item.quantity)x  \(nama)  \(harga)")
        }

        lines.append(separator)
        lines.append("Subtotal: \(PriceFormatter.format(order.subtotal))")

        // Metode bayar + nominal/kembalian (FR-10.2).
        if let metode = order.metodeBayar {
            lines.append("Bayar: \(metode)")
        }
        if let nominal = order.nominalDiterima {
            lines.append("Tunai: \(PriceFormatter.format(nominal))")
        }
        if let kembalian = order.kembalian {
            lines.append("Kembali: \(PriceFormatter.format(kembalian))")
        }

        lines.append(separator)
        lines.append("Terima kasih")

        return StrukOutput(
            teks: lines.joined(separator: "\n"),
            namaUsaha: namaUsaha,
            tanggal: order.tanggal
        )
    }

    /// Nama item: produk terdaftar pakai `name`, item manual pakai `deskripsi`.
    private func resolveNamaItem(_ item: OrderItem) -> String {
        if let productID = item.productID,
           let product = try? productRepository.fetchById(id: productID) {
            return product.name
        }
        return item.deskripsi ?? "Item"
    }
}
