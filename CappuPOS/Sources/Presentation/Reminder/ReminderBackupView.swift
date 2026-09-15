import SwiftUI
import SwiftData

/// Reminder backup mingguan (FR-10.3): muncul saat app dibuka bila sudah lewat
/// 7 hari sejak dismiss terakhir. Wajib dismiss salah satu tombol — keduanya
/// reset counter ke `now` (DECISIONS.md [2026-09-14] poin 5: "Nanti Saja" juga
/// reset, bukan skip permanen), beda hanya "Export Sekarang" buka ExportView dulu.
public struct ReminderBackupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showingExport = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 16) {
                Image(systemName: "externaldrive.badge.icloud")
                    .font(.system(size: 48))
                    .foregroundColor(.cappuPrimary)

                Text("Saatnya Backup Data")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.cappuTextPrimary)

                Text("Data usaha Anda sudah lebih dari 7 hari tidak di-backup. Export laporan Excel untuk menyimpan salinan aman.")
                    .font(.system(size: 14))
                    .foregroundColor(.cappuMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button(action: exportSekarang) {
                    Text("Export Sekarang")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.cappuPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 24)

                Button(action: nantiSaja) {
                    Text("Nanti Saja")
                        .font(.system(size: 13))
                        .foregroundColor(.cappuMuted)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .sheet(isPresented: $showingExport, onDismiss: { dismiss() }) {
            ExportView()
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text("Reminder Backup")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    /// Reset counter (poin 5), lalu buka layar Export.
    private func exportSekarang() {
        DismissReminderBackupUseCase().execute()
        showingExport = true
    }

    /// Reset counter juga — tunda reminder 7 hari berikutnya, tanpa export.
    private func nantiSaja() {
        DismissReminderBackupUseCase().execute()
        dismiss()
    }
}
