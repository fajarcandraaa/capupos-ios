import Foundation
import SwiftData

/// Satu sheet export: nama + baris sel (String saja — angka & tanggal sudah
/// diformat teks, cukup untuk laporan baca-manusia FR-13).
public struct ExportSheet {
    public let nama: String
    public let baris: [[String]]

    public init(nama: String, baris: [[String]]) {
        self.nama = nama
        self.baris = baris
    }
}

/// Export data ke .xlsx 3 sheet (FR-13.1): Transaksi, Produk, Laporan Ringkas.
/// XLSX dirakit manual (OOXML + zip) — tanpa dependency eksternal
/// (DECISIONS.md [2026-09-14] poin 4). Zip ditulis manual (stdlib Foundation,
/// method stored/uncompressed — file export kecil, hindari kompleksitas codec)
/// dengan entry OOXML langsung di root arsip (sesuai spesifikasi OPC/OOXML).
public final class ExportDataUseCase {
    private let orderRepository: OrderRepository
    private let productRepository: ProductRepository
    private let categoryRepository: CategoryRepository

    public init(
        orderRepository: OrderRepository,
        productRepository: ProductRepository,
        categoryRepository: CategoryRepository
    ) {
        self.orderRepository = orderRepository
        self.productRepository = productRepository
        self.categoryRepository = categoryRepository
    }

    /// Rakit workbook, tulis ke URL sementara, kembalikan untuk dibagikan
    /// (ShareLink / UIActivityViewController).
    public func execute() throws -> URL {
        let sheets = try buildSheets()
        return try writeWorkbook(sheets: sheets)
    }

    // MARK: - Data -> sheets

    private func buildSheets() throws -> [ExportSheet] {
        var sheets: [ExportSheet] = []

        // Sheet 1: Transaksi (riwayat lunas, FR-13.1).
        let orders = try orderRepository.fetchRiwayatLunas()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        var transaksi: [[String]] = [
            ["Tanggal", "Metode Bayar", "Subtotal", "Nominal Diterima", "Kembalian", "Jumlah Item", "Catatan"]
        ]
        for order in orders {
            transaksi.append([
                dateFormatter.string(from: order.tanggal),
                order.metodeBayar ?? "-",
                formatRp(order.subtotal),
                order.nominalDiterima.map(formatRp) ?? "-",
                order.kembalian.map(formatRp) ?? "-",
                String(order.items.count),
                order.catatan ?? "-"
            ])
        }
        sheets.append(ExportSheet(nama: "Transaksi", baris: transaksi))

        // Sheet 2: Produk (FR-13.1).
        let products = try productRepository.fetchAll()
        let kategoriByName: [UUID: String] = Dictionary(
            uniqueKeysWithValues: (try categoryRepository.fetchAll()).map { ($0.id, $0.name) }
        )
        var produk: [[String]] = [
            ["Nama", "Kategori", "Harga", "Stok", "Lacak Stok"]
        ]
        for product in products {
            let kategori = product.categoryID.flatMap { kategoriByName[$0] } ?? "-"
            produk.append([
                product.name,
                kategori,
                formatRp(product.price),
                product.stockTracked ? String(product.stockQuantity ?? 0) : "-",
                product.stockTracked ? "Ya" : "Tidak"
            ])
        }
        sheets.append(ExportSheet(nama: "Produk", baris: produk))

        // Sheet 3: Laporan Ringkas — agregat total + breakdown metode bayar.
        var ringkas: [[String]] = [["Metrik", "Nilai"]]
        let totalPendapatan = orders.reduce(0.0) { $0 + $1.subtotal }
        ringkas.append(["Jumlah transaksi lunas", String(orders.count)])
        ringkas.append(["Total pendapatan", formatRp(totalPendapatan)])
        var perMetode: [String: Double] = [:]
        for order in orders {
            let metode = order.metodeBayar ?? "(tanpa metode)"
            perMetode[metode, default: 0.0] += order.subtotal
        }
        for metode in perMetode.keys.sorted() {
            ringkas.append(["Pendapatan \(metode)", formatRp(perMetode[metode] ?? 0)])
        }
        ringkas.append(["Jumlah produk aktif", String(products.count)])
        sheets.append(ExportSheet(nama: "Laporan Ringkas", baris: ringkas))

        return sheets
    }

    private func formatRp(_ value: Double) -> String {
        PriceFormatter.format(value)
    }

    // MARK: - XLSX writer (OOXML minimal + zip via NSFileCoordinator)

    private func writeWorkbook(sheets: [ExportSheet]) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExportCapuPOS-\(UUID().uuidString)", isDirectory: true)
        let xlDir = root.appendingPathComponent("xl", isDirectory: true)
        let worksheetDir = xlDir.appendingPathComponent("worksheets", isDirectory: true)
        let relsDir = root.appendingPathComponent("_rels", isDirectory: true)
        let xlRelsDir = xlDir.appendingPathComponent("_rels", isDirectory: true)
        for dir in [root, xlDir, worksheetDir, relsDir, xlRelsDir] {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // [Content_Types].xml
        let contentTypes = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
        <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        <Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        </Types>
        """
        try contentTypes.write(to: root.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)

        // _rels/.rels
        let rootRels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
        try rootRels.write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)

        // xl/workbook.xml
        let sheetTags = sheets.enumerated().map { index, sheet in
            "<sheet name=\"\(xmlEscape(sheet.nama))\" sheetId=\"\(index + 1)\" r:id=\"rId\(index + 1)\"/>"
        }.joined()
        let workbook = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <sheets>\(sheetTags)</sheets>
        </workbook>
        """
        try workbook.write(to: xlDir.appendingPathComponent("workbook.xml"), atomically: true, encoding: .utf8)

        // xl/_rels/workbook.xml.rels
        let workbookRels = sheets.enumerated().map { index, _ in
            "<Relationship Id=\"rId\(index + 1)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet\(index + 1).xml\"/>"
        }.joined()
        let workbookRelsDoc = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        \(workbookRels)
        </Relationships>
        """
        try workbookRelsDoc.write(to: xlRelsDir.appendingPathComponent("workbook.xml.rels"), atomically: true, encoding: .utf8)

        // xl/worksheets/sheetN.xml — inlineStr semua sel, tanpa sharedStrings.
        for (index, sheet) in sheets.enumerated() {
            let rowsXML = sheet.baris.map { row in
                let cells = row.map { cell in
                    "<c t=\"inlineStr\"><is><t>\(xmlEscape(cell))</t></is></c>"
                }.joined()
                return "<row>\(cells)</row>"
            }.joined()
            let sheetXML = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
            <sheetData>\(rowsXML)</sheetData>
            </worksheet>
            """
            try sheetXML.write(
                to: worksheetDir.appendingPathComponent("sheet\(index + 1).xml"),
                atomically: true, encoding: .utf8
            )
        }

        // Zip manual — entry OOXML di root arsip (tanpa prefix folder).
        let zipURL = root.deletingLastPathComponent()
            .appendingPathComponent("Laporan-CapuPOS-\(tanggalFilename()).xlsx")
        try writeZip(directory: root, to: zipURL)

        // Bersihkan folder sumber; hasil zip tetap.
        try? FileManager.default.removeItem(at: root)
        return zipURL
    }

    // MARK: - ZIP writer (OOXML-compliant: entry di root arsip)

    /// Bungkus direktori ke .xlsx zip dengan entry relatif root (tanpa
    /// folder prefix). Method stored/uncompressed + CRC32 pure Swift.
    private func writeZip(directory: URL, to zipURL: URL) throws {
        // Kumpulkan semua file (rekursif) dengan path relatif.
        // Pakai standardizedFileURL: /var/folders/... di macOS/simulator adalah
        // symlink ke /private/var/folders/... — enumerator me-resolve symlink,
        // sedangkan `directory.path` mentah tidak, sehingga tanpa standardisasi
        // dropFirst(basePath.count) salah hitung dan sisa prefix folder bocor.
        // TANPA .skipsHiddenFiles: `_rels/.rels` (wajib OOXML) diawali titik —
        // dianggap hidden file oleh FileManager, jangan sampai ke-skip.
        var entries: [(path: String, data: Data)] = []
        let fm = FileManager.default
        let basePath = directory.standardizedFileURL.path
        if let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: []) {
            for case let fileURL as URL in enumerator {
                let isRegular = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile
                guard isRegular == true else { continue }
                let data = try Data(contentsOf: fileURL)
                let standardizedPath = fileURL.standardizedFileURL.path
                let relPath = String(standardizedPath.dropFirst(basePath.count + 1))
                entries.append((path: relPath, data: data))
            }
        }

        // Tulis ZIP manual sesuai spec (local header + data, central dir, EOCD).
        var output = Data()
        var offsets: [UInt32] = []

        // Local file headers + data (method 0 = stored, uncompressed — valid ZIP, simplify codec issues).
        for (path, data) in entries {
            let crc = crc32Checksum(data)
            let localOffset = UInt32(output.count)
            offsets.append(localOffset)

            // Local file header (30 byte + filename).
            output.append(UInt8(0x50)); output.append(UInt8(0x4B)); output.append(UInt8(0x03)); output.append(UInt8(0x04)) // PK\x03\x04
            appendLE16(&output, 20) // version needed (2.0)
            appendLE16(&output, 0) // flags
            appendLE16(&output, 0) // method 0 = stored
            appendLE16(&output, 0) // mod time (DOS)
            appendLE16(&output, 0) // mod date (DOS)
            appendLE32(&output, crc)
            appendLE32(&output, UInt32(data.count)) // compressed = uncompressed
            appendLE32(&output, UInt32(data.count))
            appendLE16(&output, UInt16(path.utf8.count))
            appendLE16(&output, 0) // extra field len
            output.append(contentsOf: path.data(using: .utf8) ?? Data())

            // Raw data (uncompressed).
            output.append(data)
        }

        // Central directory.
        let cdOffset = UInt32(output.count)
        for (i, (path, data)) in entries.enumerated() {
            let crc = crc32Checksum(data)

            output.append(UInt8(0x50)); output.append(UInt8(0x4B)); output.append(UInt8(0x01)); output.append(UInt8(0x02)) // PK\x01\x02
            appendLE16(&output, 20) // version made by
            appendLE16(&output, 20) // version needed
            appendLE16(&output, 0) // flags
            appendLE16(&output, 0) // method 0 = stored
            appendLE16(&output, 0) // mod time
            appendLE16(&output, 0) // mod date
            appendLE32(&output, crc)
            appendLE32(&output, UInt32(data.count))
            appendLE32(&output, UInt32(data.count))
            appendLE16(&output, UInt16(path.utf8.count))
            appendLE16(&output, 0) // extra field
            appendLE16(&output, 0) // comment
            appendLE16(&output, 0) // disk number start
            appendLE16(&output, 0) // internal attributes
            appendLE32(&output, 0) // external attributes
            appendLE32(&output, offsets[i])
            output.append(contentsOf: path.data(using: .utf8) ?? Data())
        }

        // End of Central Directory.
        let cdSize = UInt32(output.count) - cdOffset
        output.append(UInt8(0x50)); output.append(UInt8(0x4B)); output.append(UInt8(0x05)); output.append(UInt8(0x06)) // PK\x05\x06
        appendLE16(&output, 0) // disk number
        appendLE16(&output, 0) // disk with central dir
        appendLE16(&output, UInt16(entries.count)) // entries this disk
        appendLE16(&output, UInt16(entries.count)) // total entries
        appendLE32(&output, cdSize)
        appendLE32(&output, cdOffset)
        appendLE16(&output, 0) // comment length

        try output.write(to: zipURL)
    }

    /// Append 16-bit little-endian value ke Data.
    private func appendLE16(_ data: inout Data, _ value: UInt16) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
    }

    /// Append 32-bit little-endian value ke Data.
    private func appendLE32(_ data: inout Data, _ value: UInt32) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 24) & 0xFF))
    }

    /// CRC32 (zlib poly 0xEDB88320), pure Swift — table-based.
    private func crc32Checksum(_ data: Data) -> UInt32 {
        let table: [UInt32] = (0..<256).map { i in
            var c = UInt32(i)
            for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
            return c
        }
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let idx = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = table[idx] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }

    private func tanggalFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    /// Escape XML standar — mencegah karakter `<>&"'` merusak OOXML.
    private func xmlEscape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
