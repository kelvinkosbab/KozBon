//
//  BonjourOneShotScannerTests.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourScanning
import BonjourModels

// MARK: - BonjourOneShotScannerTests

/// Pin the time-bounded scanner's behavior. The runner is the
/// primitive both `ScanForServicesIntent` and
/// `ListDiscoveredServicesIntent` rely on for their in-process
/// scan-and-summarize flow, so its lifecycle (start → wait →
/// stop) and de-dup semantics need to fail loudly when broken.
@Suite("BonjourOneShotScanner")
@MainActor
struct BonjourOneShotScannerTests {

    // MARK: - Helpers

    private func makeService(name: String, type: String = "http") -> BonjourService {
        let serviceType = BonjourServiceType(name: type.uppercased(), type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: name,
                port: 8080
            ),
            serviceType: serviceType
        )
    }

    // MARK: - Lifecycle

    @Test("`run` starts the scanner once at the beginning of the call")
    func runStartsScannerOnce() async {
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)
        _ = await runner.run(timeout: .milliseconds(50))
        #expect(mock.startScanCallCount == 1)
    }

    @Test("`run` stops the scanner once at the end of the call")
    func runStopsScannerOnce() async {
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)
        _ = await runner.run(timeout: .milliseconds(50))
        #expect(mock.stopScanCallCount == 1)
    }

    @Test("`run` installs itself as the scanner's delegate during the scan window")
    func runTakesDelegateSlotDuringScan() async {
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)

        // Drive a scan in the background so we can observe the
        // delegate slot mid-scan. The 200 ms window gives the
        // observer task time to inspect the slot before the
        // scanner stops.
        let runTask = Task { @MainActor in
            await runner.run(timeout: .milliseconds(200))
        }

        // Give the runner a tick to install its delegate.
        try? await Task.sleep(for: .milliseconds(50))
        #expect(mock.delegate != nil, "Delegate should be installed during scan")

        _ = await runTask.value
    }

    @Test("`run` restores the prior delegate after the scan ends")
    func runRestoresPriorDelegateAfterScan() async {
        let mock = MockBonjourServiceScanner()
        let prior = TrackingDelegate()
        mock.delegate = prior

        let runner = BonjourOneShotScanner(scanner: mock)
        _ = await runner.run(timeout: .milliseconds(50))

        // The runner takes the delegate slot while it scans,
        // then must restore the original value so a long-running
        // consumer (e.g. the app's Discover tab) keeps receiving
        // callbacks after the intent finishes.
        #expect(mock.delegate === prior)
    }

    // MARK: - Result Collection

    @Test("`run` returns services discovered during the scan window")
    func runReturnsDiscoveredServices() async {
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)
        let serviceA = makeService(name: "Living Room TV")
        let serviceB = makeService(name: "Bedroom Speaker")

        let runTask = Task { @MainActor in
            await runner.run(timeout: .milliseconds(200))
        }
        // Wait briefly for the scan to start, then simulate
        // discoveries. The mock scanner forwards each one
        // through the delegate the runner installed.
        try? await Task.sleep(for: .milliseconds(50))
        mock.simulateServiceFound(serviceA)
        mock.simulateServiceFound(serviceB)

        let discovered = await runTask.value
        #expect(discovered.count == 2)
        #expect(discovered.contains(where: { $0.id == serviceA.id }))
        #expect(discovered.contains(where: { $0.id == serviceB.id }))
    }

    @Test("`run` returns an empty array when nothing is discovered before the timeout")
    func runReturnsEmptyWhenNothingFound() async {
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)
        let discovered = await runner.run(timeout: .milliseconds(50))
        #expect(discovered.isEmpty)
    }

    @Test("`run` deduplicates repeated `didAdd` callbacks for the same service id")
    func runDeduplicatesAddedServices() async {
        // The scanner re-emits `didAdd` when a service's
        // resolved fields update (addresses, TXT records).
        // The runner must collapse these by id so the
        // returned array doesn't contain duplicates.
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)
        let service = makeService(name: "Living Room TV")

        let runTask = Task { @MainActor in
            await runner.run(timeout: .milliseconds(200))
        }
        try? await Task.sleep(for: .milliseconds(50))
        mock.simulateServiceFound(service)
        mock.simulateServiceFound(service)
        mock.simulateServiceFound(service)

        let discovered = await runTask.value
        #expect(discovered.count == 1)
    }

    @Test("`run` honors `didRemove` — removed services don't appear in the returned array")
    func runHonorsRemoveCallbacks() async {
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)
        let staying = makeService(name: "Persistent")
        let leaving = makeService(name: "Transient")

        let runTask = Task { @MainActor in
            await runner.run(timeout: .milliseconds(200))
        }
        try? await Task.sleep(for: .milliseconds(50))
        mock.simulateServiceFound(staying)
        mock.simulateServiceFound(leaving)
        mock.simulateServiceLost(leaving)

        let discovered = await runTask.value
        #expect(discovered.count == 1)
        #expect(discovered.first?.id == staying.id)
    }

    @Test("`run` honors `didReset` — clears collected services if the scanner resets mid-window")
    func runHonorsResetCallbacks() async {
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)
        let beforeReset = makeService(name: "Before")
        let afterReset = makeService(name: "After")

        let runTask = Task { @MainActor in
            await runner.run(timeout: .milliseconds(200))
        }
        try? await Task.sleep(for: .milliseconds(50))
        mock.simulateServiceFound(beforeReset)
        mock.simulateReset()
        mock.simulateServiceFound(afterReset)

        let discovered = await runTask.value
        #expect(discovered.count == 1)
        #expect(discovered.first?.id == afterReset.id)
    }

    @Test("`didFailWithError` is non-fatal — the runner returns whatever was collected so far")
    func runIsRobustToErrorCallbacks() async {
        // App Intents can't surface a Bonjour-level error to
        // Siri usefully — the user just hears a meaningless
        // message. The runner must therefore continue
        // collecting and return a partial result so the
        // caller can present a graceful summary.
        let mock = MockBonjourServiceScanner()
        let runner = BonjourOneShotScanner(scanner: mock)
        let service = makeService(name: "Resilient")

        let runTask = Task { @MainActor in
            await runner.run(timeout: .milliseconds(200))
        }
        try? await Task.sleep(for: .milliseconds(50))
        mock.simulateServiceFound(service)
        mock.simulateError("transient network failure")

        let discovered = await runTask.value
        #expect(discovered.count == 1)
        #expect(discovered.first?.id == service.id)
    }

    // MARK: - Default Timeout

    @Test("Static `defaultTimeout` is 3 seconds — fits comfortably inside Siri's intent budget")
    func defaultTimeoutIsThreeSeconds() {
        #expect(BonjourOneShotScanner.defaultTimeout == .seconds(3))
    }
}

// MARK: - TrackingDelegate

/// Test-only delegate placeholder used to verify the runner
/// restores the prior delegate after a scan. Doesn't observe
/// callbacks — its presence is what we check.
@MainActor
private final class TrackingDelegate: BonjourServiceScannerDelegate {
    func didAdd(service: BonjourService) {}
    func didRemove(service: BonjourService) {}
    func didReset() {}
    func didFailWithError(description: String) {}
}
