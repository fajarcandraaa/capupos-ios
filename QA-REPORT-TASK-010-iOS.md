# QA Report — TASK-010 iOS (Verifikasi Runtime Export .xlsx)

- Role: qa-engineer
- Tanggal: 2026-09-17
- Target: branch `feat/TASK-010-REVISI-iOS-H3-Verifikasi-Export-ios`, base `main` (`3bb2df7`)
- Task contract: `tasks/task-mobile-ios/in-progress/TASK-010-REVISI-iOS-H3-Verifikasi-Export.md`
- Stack profile: `stack-profile-swift-ios.md`
- Requirement ref: FR-13.1, FR-13.3 (verifikasi runtime file .xlsx export)
- Dependency: TASK-007 (feature export diimplementasikan di TASK-007)

## Kesimpulan

**FAIL.**

File `.xlsx` hasil export **corrupt / tidak valid sebagai XLSX**. Konten internal
(3 sheet + data) benar, tapi struktur arsip ZIP tidak memenuhi spesifikasi OOXML
(Open Packaging Convention), sehingga file **tidak bisa dibuka** oleh Numbers /
Excel / Google Sheets / parser standar.

## Metode verifikasi

Feature export di TASK-007 sudah merged ke `main`, jadi TASK-010 murni verifikasi
runtime (forbidden: `Sources/**` read-only). Untuk menjalankan logic export asli
(bukan static) di sesi ini, dibuat harness CLI (macOS) yang:
- menautkan ulang **source produksi asli** (`ExportDataUseCase.swift`,
  `OrderRepository.swift`, `ProductRepository.swift`, `CategoryRepository.swift`,
  `CapuPOSDataModel.swift`, `PriceFormatter.swift`) — tidak ada salinan/duplikasi
  logika;
- menjalankan `ModelContainer` SwiftData in-memory (pola sama dengan app,
  `Schema` + model yang sama);
- seed data via repository asli (2 kategori, 3 produk, 2 transaksi lunas);
- memanggil `ExportDataUseCase().execute()` persis seperti yang dipanggil
  `ExportView.doExport()`.

Harness ada di `$CLAUDE_JOB_DIR/tmp/harness/` (tidak di-commit, di luar allowed_paths).

### Build

```
xcodebuild -project CapuPOS.xcodeproj -scheme CapuPOS -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO build
```

Hasil: **BUILD SUCCEEDED**. App ter-install + ter-launch di simulator iPhone 17
(PID 13177).

### Runtime export (harness)

```
EXPORT_URL=/var/folders/.../T/Laporan-CapuPOS-20260917.xlsx
FILE_EXISTS=true
FILE_SIZE_BYTES=3795
MAGIC=504B
```

`MAGIC=504B` = "PK" (zip). `unzip -t` lapor "No errors detected" (kompresi zip
utuh). Tapi itu hanya memvalidasi integritas arsip ZIP, bukan validitas XLSX.

## Temuan kritis (root cause)

`unzip -l` dan `zipfile.namelist()` menunjukkan **seluruh entry arsip ber-prefix
folder**:

```
ExportCapuPOS-F818D5D1-7D1F-4B2E-9A7C-D10978BB1902/[Content_Types].xml
ExportCapuPOS-F818D5D1-7D1F-4B2E-9A7C-D10978BB1902/_rels/.rels
ExportCapuPOS-F818D5D1-7D1F-4B2E-9A7C-D10978BB1902/xl/workbook.xml
ExportCapuPOS-F818D5D1-7D1F-4B2E-9A7C-D10978BB1902/xl/worksheets/sheet1.xml
...
```

Spesifikasi OPC (bagian dari OOXML/XLSX) mensyaratkan `[Content_Types].xml` berada
di **root arsip** (path tepat `[Content_Types].xml`), bukan di dalam subfolder.
Entry lain (`_rels/.rels`, `xl/workbook.xml`, …) juga harus di root.

Di file hasil: `[Content_Types].xml` ada di
`ExportCapuPOS-<UUID>/[Content_Types].xml`, bukan root. Konsekuensinya setiap
pembaca XLSX menolak file.

### Bukti parser standar

`openpyxl` (library Python de-facto untuk baca/tulis xlsx):

```
>>> openpyxl.load_workbook(<file hasil export>)
KeyError: "There is no item named '[Content_Types].xml' in the archive"
```

Ini ekuivalen dengan perilaku Numbers/Excel: keduanya menolak xlsx yang tidak
punya `[Content_Types].xml` di root.

### Root cause di kode (forbidden, read-only — untuk info ios-developer)

`ExportDataUseCase.writeWorkbook` (baris 190–216) men-zip folder hasil via
`NSFileCoordinator .forUploading`:

```swift
coordinator.coordinate(
    readingItemAt: root, options: .forUploading, ...
) { srcURL, dstURL in
    let data = try Data(contentsOf: srcURL)
    try data.write(to: dstURL)
}
```

`NSFileCoordinator` dengan `.forUploading` menghasilkan zip yang menempatkan isi
folder di bawah nama folder (preserve top-level directory). Output final `.xlsx`
dibangun dari `Data(contentsOf: srcURL)` — yaitu ZIP ber-prefix folder tersebut —
bukan ZIP yang berisi file OOXML langsung di root. Hasilnya: arsip tidak punya
`[Content_Types].xml` di root.

**Perlu dipastikan** (oleh ios-developer, di luar scope QA): zip harus dibangun
dengan entry di root arsip (tanpa prefix folder). Opsi: (a) baca isi folder lalu
buat zip manual via `Compression`/`NSFileCoordinator` dengan entry relative root,
atau (b) tulis part OOXML ke flat temp dir tanpa parent folder sebelum di-zip.

## Hasil verifikasi AC

| AC | Status | Bukti |
|----|--------|-------|
| Jalankan export .xlsx di simulator/device, ambil file via Share Sheet | PASS (runtime export) | Harness jalankan `ExportDataUseCase.execute()` asli; file `.xlsx` ter-generate (3795 bytes, magic PK). Share Sheet (`ExportView` → `ShareSheet`/`UIActivityViewController`) sudah ada di `ExportView.swift`. |
| Buka file di minimal 2 aplikasi — valid tanpa error/corrupt | **FAIL** | `openpyxl.load_workbook` gagal `KeyError: "[Content_Types].xml"`. Struktur OPC invalid. Numbers/Excel/Google Sheets (tidak terpasang di mesin ini) akan menolak dengan alasan sama — root cause struktural, bukan parser-specific. |
| Verifikasi 3 sheet muncul dengan data benar | PASS (data internal) | workbook.xml: 3 sheet `Transaksi`, `Produk`, `Laporan Ringkas`. Data tiap sheet benar (lihat tabel bawah). |
| Tulis hasil verifikasi + kesimpulan PASS/FAIL | PASS | Report ini. |
| Bila FAIL: eskalasi ke ios-developer dengan detail error | PASS | Detail root cause + bukti di atas. |
| Tidak ada perubahan di luar allowed paths | PASS | Hanya `QA-REPORT-TASK-010-iOS.md` ditulis (allowed). Harness + analisa di `$CLAUDE_JOB_DIR/tmp` (bukan repo). |

### Data 3 sheet (diverifikasi dari hasil parse XML)

**Sheet 1 — Transaksi** (header + 2 baris):

| Tanggal | Metode Bayar | Subtotal | Nominal Diterima | Kembalian | Jumlah Item | Catatan |
|---|---|---|---|---|---|---|
| 17/09/2026 12:36 | qr | Rp 15.000 | - | - | 1 | - |
| 17/09/2026 12:36 | tunai | Rp 35.000 | Rp 50.000 | Rp 15.000 | 2 | Order uji 1 |

**Sheet 2 — Produk** (header + 3 baris):

| Nama | Kategori | Harga | Stok | Lacak Stok |
|---|---|---|---|---|
| Nasi Goreng | Makanan | Rp 15.000 | 50 | Ya |
| Es Teh | Minuman | Rp 5.000 | - | Tidak |
| Kerupuk | - | Rp 2.000 | - | Tidak |

**Sheet 3 — Laporan Ringkas** (header + 5 baris):

| Metrik | Nilai |
|---|---|
| Jumlah transaksi lunas | 2 |
| Total pendapatan | Rp 50.000 |
| Pendapatan qr | Rp 15.000 |
| Pendapatan tunai | Rp 35.000 |
| Jumlah produk aktif | 3 |

Catatan: path `stockTracked=true` render "Ya" + stok `50` benar; `stockTracked=false`
render "-" + "Tidak" benar. Data sheet akurat terhadap seed.

## Batasan verifikasi (jujur)

- **Numbers / Excel / Google Sheets tidak terpasang** di mesin QA (macOS tanpa
  Numbers.app, tanpa Microsoft Excel.app). Verifikasi "buka di 2 aplikasi"
  disubstitusi dengan **parser standar `openpyxl`** yang gagal di
  `[Content_Types].xml`. Ini bukti struktural yang kuat: kegagalan bukan spesifik
  parser, melainkan arsip tidak memenuhi OPC — Numbers/Excel membaca dengan
  aturan OPC yang sama.
- `qlmanage` (QuickLook xlsx importer) hang dan di-terminate — hasil tak bisa
  dipakai sebagai bukti, tapi konsisten dengan arsip invalid.
- `xcodebuild test` / `swiftlint` tidak relevan: task verifikasi runtime, bukan
  unit; project tetap 0 test target (pola TASK-007 s/d 009).

## Eskalasi (untuk ios-developer — task lanjutan)

1. **BLOCKER — file .xlsx corrupt.** `ExportDataUseCase.writeWorkbook` men-zip
   folder hasil via `NSFileCoordinator .forUploading` sehingga semua entry
   ber-prefix nama folder; `[Content_Types].xml` tidak di root arsip.
   Perbaiki agar zip berisi file OOXML langsung di root (tanpa prefix folder).
   File target: `Sources/Domain/UseCase/ExportDataUseCase.swift` (baris 190–216).
2. Setelah fix, QA re-verify: load via `openpyxl` harus sukses + 3 sheet terbaca,
   lalu buka di Numbers/Excel di device nyata.

## Catatan Sesi

- Command test yang dijalankan: `xcodebuild ... build` (BUILD SUCCEEDED);
  harness Swift `swiftc` reuse source produksi; `unzip -t` (OK);
  `openpyxl.load_workbook` (FAIL `KeyError`).
- Hasil: **FAIL** — export berjalan, data internal benar, tapi arsip xlsx corrupt
  (OPC violation: `[Content_Types].xml` tidak di root zip).
- File yang berubah: `QA-REPORT-TASK-010-iOS.md` (baru, allowed path).
- Unresolved issue: BLOCKER di atas, eskalasi ke ios-developer.
