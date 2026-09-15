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
/// (DECISIONS.md [2026-09-14] poin 4). Zip via NSFileCoordinator `.forUploading`
/// trick: koordinasikan folder hasil jadi satu file zip.
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

        // Zip folder -> satu file .xlsx via NSFileCoordinator .forUploading.
        let zipURL = root.deletingLastPathComponent()
            .appendingPathComponent("Laporan-CapuPOS-\(tanggalFilename()).xlsx")
        var coordinatorError: NSError?
        var zipError: Error?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(
            readingItemAt: root, options: .forUploading,
            writingItemAt: zipURL, options: [],
            error: &coordinatorError
        ) { srcURL, dstURL in
            do {
                let zippedTemp = srcURL.appendingPathExtension("zip")
                _ = zippedTemp // .forUploading memberi srcURL sebagai zip virtual
                let data = try Data(contentsOf: srcURL)
                try data.write(to: dstURL)
            } catch {
                zipError = error
            }
        }
        if let error = coordinatorError ?? zipError {
            throw error
        }

        // Bersihkan folder sumber; hasil zip tetap.
        try? FileManager.default.removeItem(at: root)
        return zipURL
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
