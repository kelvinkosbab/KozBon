//
//  InternetConnectivityMonitor.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Network
import Observation
import Core

// MARK: - InternetConnectivityMonitor

/// Production ``InternetConnectivityMonitorProtocol`` backed by
/// `NWPathMonitor`.
///
/// Any satisfied path counts as connected — Wi-Fi, Ethernet, or
/// cellular — because the features that depend on this monitor talk to
/// public internet APIs, not the local link.
///
/// Path updates arrive on a system queue and are bridged into an
/// `AsyncStream` that a main-actor task consumes, the same pattern
/// `LocalNetworkMonitor` uses. Each ``start()`` builds a fresh
/// `NWPathMonitor` because a cancelled one can't be restarted.
@MainActor
@Observable
public final class InternetConnectivityMonitor: InternetConnectivityMonitorProtocol {

    // MARK: - Properties

    public private(set) var isConnected: Bool = true

    @ObservationIgnored
    private var pathMonitor: NWPathMonitor?

    @ObservationIgnored
    private var monitorTask: Task<Void, Never>?

    @ObservationIgnored
    private let logger = Logger(
        subsystem: "com.kozinga.InternetConnectivity",
        category: "InternetConnectivityMonitor"
    )

    // MARK: - Initialization

    public init() {}

    deinit {
        monitorTask?.cancel()
        pathMonitor?.cancel()
    }

    // MARK: - Lifecycle

    public func start() {
        guard monitorTask == nil else { return }

        let monitor = NWPathMonitor()
        let (stream, continuation) = AsyncStream<NWPath.Status>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        continuation.onTermination = { _ in
            monitor.cancel()
        }
        monitor.pathUpdateHandler = { path in
            continuation.yield(path.status)
        }
        monitor.start(queue: .global(qos: .utility))
        pathMonitor = monitor

        monitorTask = Task { [weak self] in
            defer { continuation.finish() }
            for await status in stream {
                self?.handle(status: status)
            }
        }
        logger.info("Started")
    }

    public func stop() {
        guard monitorTask != nil else { return }
        monitorTask?.cancel()
        monitorTask = nil
        pathMonitor?.cancel()
        pathMonitor = nil
        logger.info("Stopped")
    }

    // MARK: - Path Classification

    /// `.requiresConnection` means the system could connect on demand
    /// (e.g. a VPN or cellular that hasn't come up yet) but no route
    /// exists now, so it counts as offline.
    nonisolated static func isConnected(status: NWPath.Status) -> Bool {
        status == .satisfied
    }

    private func handle(status: NWPath.Status) {
        let newValue = Self.isConnected(status: status)
        guard newValue != isConnected else { return }
        isConnected = newValue
        logger.info("Internet connectivity changed: isConnected=\(newValue)")
    }
}
