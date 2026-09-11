import SwiftData
import Foundation

@Model
public final class Product {
    public var id: UUID
    public var name: String
    public var price: Double
    public var categoryID: UUID?
    public var image: Data?
    public var productDescription: String?
    public var stockTracked: Bool = false
    public var stockQuantity: Int?
    public var stockMinimal: Int?
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    public var isDeleted: Bool = false

    public init(
        id: UUID = UUID(),
        name: String,
        price: Double,
        categoryID: UUID? = nil,
        image: Data? = nil,
        productDescription: String? = nil,
        stockTracked: Bool = false,
        stockQuantity: Int? = 0,
        stockMinimal: Int? = 0
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.categoryID = categoryID
        self.image = image
        self.productDescription = productDescription
        self.stockTracked = stockTracked
        self.stockQuantity = stockQuantity
        self.stockMinimal = stockMinimal
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
public final class Category {
    public var id: UUID
    public var name: String
    public var details: String?
    public var order: Int = 0

    public init(id: UUID = UUID(), name: String, description: String? = nil, order: Int = 0) {
        self.id = id
        self.name = name
        self.details = description
        self.order = order
    }
}

// MARK: - Order (Transaksi) — TASK-005
// Paritas field dengan Android OrderEntity/OrderDetailEntity (Room), lihat DECISIONS.md
// [2026-09-11]: status/statusPo literal snake_case lintas platform, `deskripsi`
// nullable per item (transaksi manual), SwiftData lightweight migration menangani
// field additive otomatis — tidak perlu VersionedSchema.

/// Literal status transaksi (snake_case, identik Android `OrderEntity.status`).
public enum OrderStatus {
    public static let belumBayar = "belum_bayar"
}

/// Literal status PO (snake_case, identik Android `OrderEntity.statusPo`).
/// Null bila bukan PO. FR-05.5: transisi `selesai` -> `dibatalkan` dilarang.
public enum StatusPO {
    public static let menungguKonfirmasi = "menunggu_konfirmasi"
    public static let diproses = "diproses"
    public static let siap = "siap"
    public static let selesai = "selesai"
    public static let dibatalkan = "dibatalkan"

    /// Urutan kanonik 5 tahap FR-05 (untuk UI picker).
    public static let allCasesInOrder: [String] = [
        menungguKonfirmasi, diproses, siap, selesai, dibatalkan
    ]

    /// FR-05.5: dari status `selesai`, `dibatalkan` tidak boleh dipilih.
    public static func allowedTargets(from current: String?) -> [String] {
        guard let current = current else { return allCasesInOrder }
        if current == selesai {
            return allCasesInOrder.filter { $0 != dibatalkan }
        }
        return allCasesInOrder
    }
}

@Model
public final class Order {
    public var id: UUID
    public var status: String = OrderStatus.belumBayar
    public var statusPo: String? = nil
    public var metodeBayar: String? = nil
    public var subtotal: Double = 0.0
    public var nominalDiterima: Double? = nil
    public var kembalian: Double? = nil
    public var catatan: String? = nil
    public var tanggal: Date = Date()
    public var isHidden: Bool = false
    public var isDeleted: Bool = false
    public var deletedAt: Date? = nil
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \OrderItem.order)
    public var items: [OrderItem] = []

    public init(
        id: UUID = UUID(),
        status: String = OrderStatus.belumBayar,
        statusPo: String? = nil,
        metodeBayar: String? = nil,
        subtotal: Double = 0.0,
        nominalDiterima: Double? = nil,
        kembalian: Double? = nil,
        catatan: String? = nil,
        tanggal: Date = Date(),
        isHidden: Bool = false,
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.status = status
        self.statusPo = statusPo
        self.metodeBayar = metodeBayar
        self.subtotal = subtotal
        self.nominalDiterima = nominalDiterima
        self.kembalian = kembalian
        self.catatan = catatan
        self.tanggal = tanggal
        self.isHidden = isHidden
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class OrderItem {
    public var id: UUID
    public var productID: UUID?
    public var quantity: Int = 0
    public var price: Double = 0.0
    /// Transaksi manual: deskripsi bebas per item non-produk (nullable).
    /// Additive — SwiftData lightweight migration menangani otomatis.
    public var deskripsi: String? = nil
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public var order: Order?

    public init(
        id: UUID = UUID(),
        productID: UUID? = nil,
        quantity: Int = 0,
        price: Double = 0.0,
        deskripsi: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.productID = productID
        self.quantity = quantity
        self.price = price
        self.deskripsi = deskripsi
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}