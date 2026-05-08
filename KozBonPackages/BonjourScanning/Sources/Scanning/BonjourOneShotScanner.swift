//
//  BonjourOneShotScanner.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - BonjourOneShotScanner

/// Helper that wraps a ``BonjourServiceScannerProtocol`` and a
/// delegate-collector to run a **time-bounded** scan and return
/// the discovered services as a single value.
///
/// Designed for App Intents and other one-shot contexts (Siri,
/// Shortcuts, Spotlight previews) where the long-running
/// delegate-driven scanner pattern doesn't fit. The continuous
/// scanner is the right primitive for the Discover tab — every
/// `didAdd` updates the live UI — but a Siri intent has a single
/// budgeted invocation: it needs the list once, in bulk, with
/// no callbacks fired afterward.
///
/// The runner takes a scanner instance via the injectable
/// ``BonjourServiceScannerProtocol`` so tests can drive it with
/// ``MockBonjourServiceScanner`` from `MockDependencies.swift`
/// without touching real Bonjour APIs.
@MainActor
public final class BonjourOneShotScanner {

    // MARK: - Defaults

    /// Default scan duration. Picked so the typical home network
    /// returns most services (Bonjour discovery is sub-second for
    /// services that respond eagerly), while leaving headroom
    /// inside Siri's ~30 s intent budget for prompt building and
    /// model invocation.
    public static let defaultTimeout: Duration = .seconds(3)

    // MARK: - Properties

    private let scanner: BonjourServiceScannerProtocol
    private let collector = Collector()

    // MARK: - Init

    /// Creates a runner that drives the supplied scanner.
    ///
    /// The runner takes ownership of the scanner's delegate slot
    /// for the duration of ``run(timeout:publishedServices:)`` —
    /// callers shouldn't share the same scanner with another
    /// long-running consumer (e.g. the app's Discover tab) at the
    /// same time, as the delegate would get clobbered.
    public init(scanner: BonjourServiceScannerProtocol) {
        self.scanner = scanner
    }

    // MARK: - Run

    /// Starts the scanner, waits `timeout`, stops the scanner, and
    /// returns the services collected during the window.
    ///
    /// - Parameters:
    ///   - timeout: How long to listen for `didAdd(service:)`
    ///     callbacks before stopping. Defaults to
    ///     ``defaultTimeout``.
    ///   - publishedServices: Services published from this device
    ///     to forward to the scanner so it discovers their types
    ///     too. Defaults to empty since intent contexts usually
    ///     don't have an active publisher.
    /// - Returns: The unique services discovered in the window,
    ///   in arrival order. `didRemove` callbacks during the
    ///   window are honored — the returned array reflects the
    ///   net set, not a cumulative add log.
    public func run(
        timeout: Duration = defaultTimeout,
        publishedServices: Set<BonjourService> = []
    ) async -> [BonjourService] {
        // Snapshot the prior delegate so we can restore it on
        // exit — the scanner instance might be shared with a
        // caller that also wants delegate callbacks.
        let priorDelegate = scanner.delegate
        scanner.delegate = collector
        scanner.startScan(publishedServices: publishedServices)

        // `Task.sleep` is the right primitive: cooperatively
        // cancellable, wakes early on cancellation, doesn't
        // block the actor. If the surrounding intent is
        // cancelled (e.g. Siri timeout), we exit cleanly.
        try? await Task.sleep(for: timeout)

        scanner.stopScan()
        scanner.delegate = priorDelegate
        return collector.snapshot()
    }
}

// MARK: - Collector

/// Internal `BonjourServiceScannerDelegate` that captures
/// `didAdd` callbacks into a list and honors `didRemove` /
/// `didReset` to keep the snapshot consistent.
///
/// Public-API consumers don't see this type — they only get the
/// final array out of ``BonjourOneShotScanner/run(timeout:publishedServices:)``.
@MainActor
private final class Collector: BonjourServiceScannerDelegate {

    private var services: [BonjourService] = []

    func didAdd(service: BonjourService) {
        // De-dup by `id` (the scanner's stable per-session
        // identifier) — `BonjourServiceScanner` re-emits
        // `didAdd` when a service's resolved fields update,
        // and we don't want duplicates in the returned array.
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
        } else {
            services.append(service)
        }
    }

    func didRemove(service: BonjourService) {
        services.removeAll { $0.id == service.id }
    }

    func didReset() {
        services.removeAll()
    }

    func didFailWithError(description: String) {
        // Errors are non-fatal for the one-shot use case —
        // we still return whatever was collected before the
        // failure. The caller can present a partial list with
        // a "scan was interrupted" caveat if appropriate; the
        // alternative (throwing) would force every caller to
        // handle a transient delegate error that doesn't
        // actually break the result.
    }

    func snapshot() -> [BonjourService] {
        services
    }
}
