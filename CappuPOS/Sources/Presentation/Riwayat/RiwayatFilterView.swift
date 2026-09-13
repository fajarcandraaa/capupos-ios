import SwiftUI
import SwiftData

/// Filter sheet riwayat (FR-07.1): kategori, rentang tanggal, metode bayar.
struct RiwayatFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filter: FilterRiwayat
    let categories: [Category]

    @State private var kategoriID: UUID?
    @State private var dariTanggal: Date?
    @State private var sampaiTanggal: Date?
    @State private var metodeBayar: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Kategori") {
                    Picker("", selection: $kategoriID) {
                        Text("Semua").tag(UUID?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(UUID?.some(category.id))
                        }
                    }
                    .labelsHidden()
                }

                Section("Metode Bayar") {
                    Picker("", selection: $metodeBayar) {
                        Text("Semua").tag(String?.none)
                        Text("Tunai").tag(String?.some(MetodeBayar.tunai))
                        Text("Non-Tunai").tag(String?.some(MetodeBayar.nonTunai))
                    }
                    .labelsHidden()
                }

                Section("Tanggal") {
                    DatePicker("Dari", selection: Binding(
                        get: { dariTanggal ?? Date() },
                        set: { dariTanggal = $0 }
                    ), displayedComponents: .date)
                    DatePicker("Sampai", selection: Binding(
                        get: { sampaiTanggal ?? Date() },
                        set: { sampaiTanggal = $0 }
                    ), displayedComponents: .date)
                    Button("Reset Tanggal") {
                        dariTanggal = nil
                        sampaiTanggal = nil
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terapkan") {
                        filter = FilterRiwayat(
                            kategoriID: kategoriID,
                            dariTanggal: dariTanggal,
                            sampaiTanggal: sampaiTanggal,
                            metodeBayar: metodeBayar
                        )
                        dismiss()
                    }
                }
            }
            .onAppear {
                kategoriID = filter.kategoriID
                dariTanggal = filter.dariTanggal
                sampaiTanggal = filter.sampaiTanggal
                metodeBayar = filter.metodeBayar
            }
        }
    }
}
