import Combine
import Foundation

@available(macOS 10.15, *)
@MainActor
final class SplashViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var appReady = false

    func startApp() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        appReady = true
    }
}
