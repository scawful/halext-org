//
//  NetworkMonitor.swift
//  Cafe
//
//  Monitor network connectivity status
//

import Foundation
import Network

@MainActor
@Observable
class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool = true
    var connectionType: ConnectionType = .wifi

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            _Concurrency.Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else {
                    self.connectionType = .unknown
                }

                if self.isConnected {
                    print("🌍 Network connected: \(self.connectionType)")
                    // Trigger sync when connection is restored
                    NotificationCenter.default.post(name: .networkConnected, object: nil)
                } else {
                    print("📴 Network disconnected")
                    NotificationCenter.default.post(name: .networkDisconnected, object: nil)
                }
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkConnected = Notification.Name("networkConnected")
    static let networkDisconnected = Notification.Name("networkDisconnected")
}
