import Foundation

enum CloudSyncUnavailableReason: Equatable {
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine
    case notConfigured
}

enum CloudSyncState: Equatable {
    case checking
    case syncing
    case ready(lastSyncAt: Date?)
    case unavailable(reason: CloudSyncUnavailableReason)
    case error(message: String)
}
