import SwiftUI

/// Form tambah item transaksi manual: nominal bebas + deskripsi (AC: item non-produk
/// ke transaksi yang sama). Reuse CappuTextField/CappuTextArea (EmptyStateView.swift).
struct TransaksiManualItemView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var nominalText = ""
    @State private var deskripsi = ""

    let onSave: (Double, String) -> Void

    private var nominal: Double {
        Double(nominalText.filter { $0.isNumber || $0 == "." }) ?? 0
    }

    private var canSave: Bool {
        nominal > 0 && !deskripsi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 20) {
                    CappuTextField(label: "Nominal", placeholder: "0", text: $nominalText, numberPad: true)
                    CappuTextArea(label: "Deskripsi", placeholder: "Deskripsi item", text: $deskripsi)
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(Color.white)
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

            Text("Tambah Item Manual")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var saveButton: some View {
        Button {
            onSave(nominal, deskripsi.trimmingCharacters(in: .whitespacesAndNewlines))
            dismiss()
        } label: {
            Text("Tambah ke Transaksi")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(canSave ? Color.cappuPrimary : Color.cappuDisabled)
                .cornerRadius(24)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }
}
