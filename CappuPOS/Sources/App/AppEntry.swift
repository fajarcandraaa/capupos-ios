import SwiftUI
import SwiftData

@MainActor
@main
struct CapuPOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // TASK-005: Order + OrderItem WAJIB didaftarkan agar SwiftData persist.
        // TASK-006: StockHistoryEntry (histori stok FR-09.2).
        // TASK-007: Store (profil usaha, FR-10) — singleton dijaga StoreRepository.
        .modelContainer(for: [Product.self, Category.self, Order.self, OrderItem.self, StockHistoryEntry.self, Store.self])
    }
}

struct ContentView: View {
    @State private var showSplash = true
    @State private var showOnboarding = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if showSplash {
                SplashScreen()
            } else if showOnboarding {
                EmptyStateView(onClose: {
                    showOnboarding = false
                    showSplash = false
                })
            } else {
                HomeView()
            }
        }
        .task {
            await checkIfFirstTime()
        }
    }

    private func checkIfFirstTime() async {
        let useCase = CekProdukKosongUseCase(context: modelContext)
        if useCase.isEmpty() {
            await MainActor.run {
                showOnboarding = true
                showSplash = false
            }
        } else {
            await MainActor.run { showSplash = false }
        }
    }
}

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color(red: 0.086, green: 0.478, blue: 0.835)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image("CappuPOSLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)

                    Text("Cappu POS")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(spacing: 8) {
                    Text("Versi aplikasi 1.0")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct HomeView: View {
    @State private var showingTransaksi = false
    @State private var showingBelumBayar = false
    // TASK-006: entry point Pembayaran / Riwayat / Laporan (DECISIONS.md
    // [2026-09-13] poin 3).
    @State private var showingPembayaran = false
    @State private var showingRiwayat = false
    @State private var showingLaporan = false
    // TASK-007: menu "Profil/Pengaturan" gabungan (Profil Usaha + Export,
    // DECISIONS.md [2026-09-14] poin 7) + reminder backup (FR-10.3).
    @State private var showingProfil = false
    @State private var showingReminder = false

    var body: some View {
        NavigationView {
            ListProdukView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingTransaksi = true
                        } label: {
                            Image(systemName: "cart")
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showingBelumBayar = true
                        } label: {
                            Image(systemName: "clock")
                        }
                        Button {
                            showingPembayaran = true
                        } label: {
                            Image(systemName: "banknote")
                        }
                        Button {
                            showingRiwayat = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        Button {
                            showingLaporan = true
                        } label: {
                            Image(systemName: "chart.bar")
                        }
                        Button {
                            showingProfil = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
        .sheet(isPresented: $showingTransaksi) {
            TransaksiView()
        }
        .sheet(isPresented: $showingBelumBayar) {
            BelumBayarListView()
        }
        .sheet(isPresented: $showingPembayaran) {
            PembayaranEntryView()
        }
        .sheet(isPresented: $showingRiwayat) {
            RiwayatListView()
        }
        .sheet(isPresented: $showingLaporan) {
            LaporanView()
        }
        .sheet(isPresented: $showingProfil) {
            ProfilUsahaView()
        }
        .sheet(isPresented: $showingReminder) {
            ReminderBackupView()
        }
        .task {
            // TASK-007 FR-10.3: reminder backup mingguan, pola .task sama dengan
            // CekProdukKosongUseCase (DECISIONS.md [2026-09-14] poin 5).
            if CekReminderBackupUseCase().execute() {
                showingReminder = true
            }
        }
    }
}