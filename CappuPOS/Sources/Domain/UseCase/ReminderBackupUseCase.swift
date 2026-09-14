import Foundation

/// Cek apakah perlu munculkan reminder backup (FR-10.3): terlalu lama (> 7 hari)
/// sejak dismiss terakhir. State aplikasi-lokal di `UserDefaults` — bukan entitas
/// DB (tidak butuh sync/laporan).
public final class CekReminderBackupUseCase {
    /// Interval reminder: 7 hari (FR-10.3).
    static let interval7Hari: TimeInterval = 7 * 24 * 60 * 60
    static let keyLastDismiss = "backup_reminder_last_dismissed_at"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// `true` bila belum pernah dismiss ATAU sudah lewat 7 hari sejak dismiss.
    public func execute(now: Date = Date()) -> Bool {
        guard let last = defaults.object(forKey: Self.keyLastDismiss) as? Date else {
            return true
        }
        return now.timeIntervalSince(last) >= Self.interval7Hari
    }
}

/// Catat dismiss reminder backup (FR-10.3) — menunda reminder berikutnya 7 hari.
public final class DismissReminderBackupUseCase {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func execute(now: Date = Date()) {
        defaults.set(now, forKey: CekReminderBackupUseCase.keyLastDismiss)
    }
}
