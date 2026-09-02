import SwiftUI
import SwiftData

@MainActor
@main
struct CapuPOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Product.self, Category.self])
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
    var body: some View {
        NavigationView {
            ListProdukView()
        }
    }
}