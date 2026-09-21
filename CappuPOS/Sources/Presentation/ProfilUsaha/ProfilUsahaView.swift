import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Form profil usaha (FR-10.1): edit nama, logo, kategori, deskripsi, alamat,
/// telepon. Simpan validasi di useCase + repo (nama/alamat wajib). Logo disimpan
/// sebagai path file lokal (field `logo` String? — bukan data biner, DECISIONS.md
/// [2026-09-14] poin 3).
public struct ProfilUsahaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var nama = ""
    @State private var logoPath = ""
    /// Path logo yang tersimpan di Store saat form dibuka — file lama hanya
    /// dihapus saat simpan sukses, bukan saat edit di form (cancel tidak boleh
    /// meninggalkan Store menunjuk file yang sudah terhapus).
    @State private var storedLogoPath: String?
    @State private var kategoriUsaha = ""
    @State private var deskripsi = ""
    @State private var alamat = ""
    @State private var telepon = ""
    @State private var email = ""
    @State private var no_hp = ""
    @State private var logoImage: UIImage?
    @State private var logoSelection: PhotosPickerItem?
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showingExport = false

    public init() {}

    private var storeRepository: StoreRepository {
        StoreRepository(context: modelContext)
    }

    private var fetchUseCase: FetchProfilUsahaUseCase {
        FetchProfilUsahaUseCase(storeRepository: storeRepository)
    }

    private var simpanUseCase: SimpanProfilUsahaUseCase {
        SimpanProfilUsahaUseCase(storeRepository: storeRepository)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Form {
                Section(header: Text("Logo")) {
                    HStack {
                        if let logoImage = logoImage {
                            Image(uiImage: logoImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo")
                                .frame(width: 64, height: 64)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                        }

                        PhotosPicker(selection: $logoSelection, matching: .images) {
                            Text("Pilih Logo")
                        }
                        .onChange(of: logoSelection) { _, newItem in
                            muatLogo(newItem)
                        }

                        if logoImage != nil {
                            Button(role: .destructive, action: hapusLogo) {
                                Text("Hapus")
                            }
                        }
                    }
                }

                Section(header: Text("Nama Usaha")) {
                    TextField("Nama", text: $nama)
                }

                Section(header: Text("Alamat")) {
                    TextField("Alamat", text: $alamat)
                }

                Section(header: Text("Telepon")) {
                    TextField("Telepon", text: $telepon)
                }

                Section(header: Text("Email")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }

                Section(header: Text("Nomor HP")) {
                    TextField("Nomor HP", text: $no_hp)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section(header: Text("Kategori Usaha")) {
                    TextField("Kategori", text: $kategoriUsaha)
                }

                Section(header: Text("Deskripsi")) {
                    TextEditor(text: $deskripsi)
                        .frame(minHeight: 80)
                }

                Section {
                    Button(action: simpan) {
                        Text("Simpan")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.cappuPrimary)
                    }
                }
            }
        }
        .background(Color.white)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingExport) {
            ExportView()
        }
        .task {
            await muatProfil()
        }
    }

    /// Menu gabungan Profil/Pengaturan (FR-13.2, DECISIONS.md [2026-09-14]
    /// poin 7): tombol Export ikut di sini, bukan entry terpisah.
    private var header: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.cappuTextPrimary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Text("Profil / Pengaturan")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()

            Button(action: { showingExport = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.cappuTextPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func muatProfil() async {
        do {
            let store = try fetchUseCase.execute()
            await MainActor.run {
                nama = store.nama
                logoPath = store.logo ?? ""
                storedLogoPath = store.logo
                kategoriUsaha = store.kategoriUsaha ?? ""
                deskripsi = store.deskripsi ?? ""
                alamat = store.alamat
                telepon = store.telepon ?? ""
                email = store.email ?? ""
                no_hp = store.no_hp ?? ""
                if let path = store.logo, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                    logoImage = UIImage(data: data)
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "Gagal memuat profil: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    /// Simpan foto terpilih ke Documents/, catat path-nya (bukan data biner di DB).
    /// Review #2: write gagal jangan diam-diam — path rusak jangan tersimpan.
    /// File lama (storedLogoPath) baru dihapus saat simpan() sukses, bukan di
    /// sini — supaya cancel form tidak meninggalkan Store menunjuk file hilang.
    private func muatLogo(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = dir.appendingPathComponent("store-logo-\(UUID().uuidString).jpg")
            guard let jpeg = image.jpegData(compressionQuality: 0.8) else {
                await MainActor.run { tampilkanErrorLogo("Gagal memproses gambar logo.") }
                return
            }
            do {
                try jpeg.write(to: fileURL)
            } catch {
                await MainActor.run { tampilkanErrorLogo("Gagal menyimpan logo: \(error.localizedDescription)") }
                return
            }
            await MainActor.run {
                logoImage = image
                logoPath = fileURL.path
            }
        }
    }

    private func hapusLogo() {
        logoImage = nil
        logoPath = ""
        logoSelection = nil
    }

    private func tampilkanErrorLogo(_ pesan: String) {
        alertMessage = pesan
        showingAlert = true
    }

    private func simpan() {
        do {
            _ = try simpanUseCase.execute(
                nama: nama,
                logo: logoPath.isEmpty ? nil : logoPath,
                kategoriUsaha: kategoriUsaha.isEmpty ? nil : kategoriUsaha,
                deskripsi: deskripsi.isEmpty ? nil : deskripsi,
                alamat: alamat,
                telepon: telepon.isEmpty ? nil : telepon,
                email: email.isEmpty ? nil : email,
                no_hp: no_hp.isEmpty ? nil : no_hp
            )
            // Bersihkan file logo lama (tidak di-gunakan lagi di Store).
            // Hanya saat simpan sukses — jangan hapus saat cancel/error.
            if let pathLama = storedLogoPath, pathLama != logoPath, !pathLama.isEmpty {
                try? FileManager.default.removeItem(atPath: pathLama)
            }
            dismiss()
        } catch let error as NSError {
            alertMessage = error.userInfo[NSLocalizedDescriptionKey] as? String ?? "Gagal simpan profil"
            showingAlert = true
        } catch {
            alertMessage = "Gagal simpan: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
