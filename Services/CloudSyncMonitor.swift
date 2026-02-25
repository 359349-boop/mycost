import CloudKit
import CoreData
import Foundation
import UIKit

@MainActor
final class CloudSyncMonitor: ObservableObject {
    @Published private(set) var state: CloudSyncState = .checking

    private let container: CKContainer
    private let isCloudKitStoreEnabled: Bool
    private let startupErrorMessage: String?
    private var activeSyncEventCount = 0
    private var lastSuccessfulSyncAt: Date?
    private var observers: [NSObjectProtocol] = []

    init(
        isCloudKitStoreEnabled: Bool,
        startupErrorMessage: String?,
        containerIdentifier: String = CloudSyncConfig.cloudKitContainerIdentifier
    ) {
        self.isCloudKitStoreEnabled = isCloudKitStoreEnabled
        self.startupErrorMessage = startupErrorMessage
        container = CKContainer(identifier: containerIdentifier)

        subscribeToNotifications()
        refresh()
    }

    deinit {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
    }

    func refresh() {
        if let startupErrorMessage {
            state = .error(message: startupErrorMessage)
            return
        }

        guard isCloudKitStoreEnabled else {
            state = .unavailable(reason: .notConfigured)
            return
        }

        state = .checking
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.state = .error(message: error.localizedDescription)
                    return
                }
                self.applyAccountStatus(status)
            }
        }
    }

    private func subscribeToNotifications() {
        let center = NotificationCenter.default

        let accountChanged = center.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        let foreground = center.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        let eventChanged = center.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleCloudKitEvent(notification)
            }
        }

        observers = [accountChanged, foreground, eventChanged]
    }

    private func applyAccountStatus(_ status: CKAccountStatus) {
        switch status {
        case .available:
            state = .ready(lastSyncAt: lastSuccessfulSyncAt)
        case .noAccount:
            state = .unavailable(reason: .noAccount)
        case .restricted:
            state = .unavailable(reason: .restricted)
        case .temporarilyUnavailable:
            state = .unavailable(reason: .temporarilyUnavailable)
        case .couldNotDetermine:
            state = .unavailable(reason: .couldNotDetermine)
        @unknown default:
            state = .unavailable(reason: .couldNotDetermine)
        }
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        guard isCloudKitStoreEnabled else {
            state = .unavailable(reason: .notConfigured)
            return
        }

        guard
            let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
            as? NSPersistentCloudKitContainer.Event
        else {
            return
        }

        if event.endDate == nil {
            activeSyncEventCount += 1
            state = .syncing
            return
        }

        activeSyncEventCount = max(0, activeSyncEventCount - 1)

        if let error = event.error {
            state = .error(message: error.localizedDescription)
            return
        }

        if activeSyncEventCount > 0 {
            state = .syncing
            return
        }

        lastSuccessfulSyncAt = Date()
        state = .ready(lastSyncAt: lastSuccessfulSyncAt)
    }
}
