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
            await MainActor.run { showOnboarding = true }
        } else {
            await MainActor.run { showSplash = false }
        }
    }
}

struct SplashScreen: View {
    var body: some View {
        VStack {
            Text("CappuPOS")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            Text("Home Screen")
                .navigationTitle("Home")
        }
    }
}