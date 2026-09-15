import SwiftUI
import SwiftData
import UIKit

/// Tampilan struk teks (FR-10.2): render `StrukOutput` dari order lunas.
/// Copy ke clipboard; share via UIActivityViewController (teks polos).
public struct StrukView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let orderID: UUID

    @State private var struk: StrukOutput?
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showingShare = false

    public init(orderID: UUID) {
        self.orderID = orderID
    }

    private var useCase: GenerateStrukUseCase {
        GenerateStrukUseCase(
            orderRepository: OrderRepository(context: modelContext),
            productRepository: ProductRepository(context: modelContext),
            storeRepository: StoreRepository(context: modelContext)
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            if let struk = struk {
                ScrollView {
                    Text(struk.teks)
                        .font(.system(.body, design: .monospaced))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.white)

                HStack(spacing: 12) {
                    Button(action: copyStruk) {
                        Label("Salin", systemImage: "doc.on.doc")
                    }
                    Button(action: { showingShare = true }) {
                        Label("Bagikan", systemImage: "square.and.arrow.up")
                    }
                }
                .padding(16)
            } else {
                Spacer()
                Text("Menyiapkan struk…")
                    .foregroundColor(.cappuMuted)
                Spacer()
            }
        }
        .background(Color.white)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingShare) {
            if let struk = struk {
                ShareSheet(activityItems: [struk.teks])
            }
        }
        .task {
            generate()
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

            Text("Struk")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cappuTextPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func generate() {
        do {
            struk = try useCase.execute(orderID: orderID)
        } catch {
            alertMessage = "Gagal membuat struk: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func copyStruk() {
        guard let struk = struk else { return }
        UIPasteboard.general.string = struk.teks
        alertMessage = "Struk disalin ke clipboard"
        showingAlert = true
    }
}

/// Pembungkus UIActivityViewController (teks/URL) — tidak ada ShareLink
/// karena share teks polos (bukan item file).
public struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    public init(activityItems: [Any]) {
        self.activityItems = activityItems
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
