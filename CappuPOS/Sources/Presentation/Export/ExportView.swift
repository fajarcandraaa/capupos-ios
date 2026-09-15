import SwiftUI
import SwiftData

/// Layar Export (FR-13.1): tombol export 3-sheet Excel, share via iOS share
/// sheet (UIActivityViewController). Dipanggil dari Reminder (Export Sekarang)
/// dan Profil/Pengaturan.
public struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var exportURL: URL?
    @State private var showingShare = false
    @State private var isExporting = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up.on.square")
                    .font(.system(size: 48))
                    .foregroundColor(.cappuPrimary)

                Text("Export Excel")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.cappuTextPrimary)

                Text("3 sheet: Transaksi, Produk, Laporan Ringkas")
                    .font(.system(size: 14))
                    .foregroundColor(.cappuMuted)

                Button(action: doExport) {
                    HStack {
                        if isExporting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Export Sekarang")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cappuPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isExporting)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingShare) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
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

            Text("Export")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func doExport() {
        isExporting = true
        let useCase = ExportDataUseCase(
            orderRepository: OrderRepository(context: modelContext),
            productRepository: ProductRepository(context: modelContext),
            categoryRepository: CategoryRepository(context: modelContext)
        )
        do {
            exportURL = try useCase.execute()
            showingShare = true
        } catch {
            alertMessage = "Gagal export: \(error.localizedDescription)"
            showingAlert = true
        }
        isExporting = false
    }
}
