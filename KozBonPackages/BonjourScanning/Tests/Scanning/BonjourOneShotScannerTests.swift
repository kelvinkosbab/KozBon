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

    /// A runner whose scan window ends immediately, for tests that
    /// only check what happens around the window.
    private func makeImmediateRunner(scanner: MockBonjourServiceScanner) -> BonjourOneShotScanner {
        BonjourOneShotScanner(scanner: scanner, waitForScanWindow: { _ in })
    }

    /// Starts a scan behind `gate` and returns once the runner is
    /// listening, so the caller can simulate callbacks and then
    /// `gate.close()`.
    private func startGatedScan(
        scanner: MockBonjourServiceScanner,
        gate: ScanWindowGate
    ) async -> Task<[BonjourService], Never> {
        let runner = BonjourOneShotScanner(scanner: scanner, waitForScanWindow: gate.wait)
        let runTask = Task { @MainActor in
            await runner.run()
        }
        await gate.waitUntilOpen()
        return runTask
    }

    // MARK: - Lifecycle

    @Test("`run` starts the scanner once at the beginning of the call")
    func runStartsScannerOnce() async {
        let mock = MockBonjourServiceScanner()
        let runner = makeImmediateRunner(scanner: mock)
        _ = await runner.run()
        #expect(mock.startScanCallCount == 1)
    }

    @Test("`run` stops the scanner once at the end of the call")
    func runStopsScannerOnce() async {
        let mock = MockBonjourServiceScanner()
        let runner = makeImmediateRunner(scanner: mock)
        _ = await runner.run()
        #expect(mock.stopScanCallCount == 1)
    }

    @Test("`run` installs itself as the scanner's delegate during the scan window")
    func runTakesDelegateSlotDuringScan() async {
        let mock = MockBonjourServiceScanner()
        let gate = ScanWindowGate()
        let runTask = await startGatedScan(scanner: mock, gate: gate)

        #expect(mock.delegate != nil, "Delegate should be installed during scan")

        gate.close()
        _ = await runTask.value
    }

    @Test("`run` waits for exactly the requested timeout")
    func runWaitsForRequestedTimeout() async {
        let mock = MockBonjourServiceScanner()
        let gate = ScanWindowGate()
        let runner = BonjourOneShotScanner(scanner: mock, waitForScanWindow: gate.wait)
        gate.close()

        _ = await runner.run(timeout: .milliseconds(1_500))

        #expect(gate.requestedDurations == [.milliseconds(1_500)])
    }

    @Test("`run` restores the prior delegate after the scan ends")
    func runRestoresPriorDelegateAfterScan() async {
        let mock = MockBonjourServiceScanner()
        let prior = TrackingDelegate()
        mock.delegate = prior

        let runner = makeImmediateRunner(scanner: mock)
        _ = await runner.run()

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
        let gate = ScanWindowGate()
        let serviceA = makeService(name: "Living Room TV")
        let serviceB = makeService(name: "Bedroom Speaker")

        let runTask = await startGatedScan(scanner: mock, gate: gate)
        mock.simulateServiceFound(serviceA)
        mock.simulateServiceFound(serviceB)
        gate.close()

        let discovered = await runTask.value
        #expect(discovered.count == 2)
        #expect(discovered.contains(where: { $0.id == serviceA.id }))
        #expect(discovered.contains(where: { $0.id == serviceB.id }))
    }

    @Test("`run` returns an empty array when nothing is discovered before the timeout")
    func runReturnsEmptyWhenNothingFound() async {
        let mock = MockBonjourServiceScanner()
        let runner = makeImmediateRunner(scanner: mock)
        let discovered = await runner.run()
        #expect(discovered.isEmpty)
    }

    @Test("`run` deduplicates repeated `didAdd` callbacks for the same service id")
    func runDeduplicatesAddedServices() async {
        // The scanner re-emits `didAdd` when a service's
        // resolved fields update (addresses, TXT records).
        // The runner must collapse these by id so the
        // returned array doesn't contain duplicates.
        let mock = MockBonjourServiceScanner()
        let gate = ScanWindowGate()
        let service = makeService(name: "Living Room TV")

        let runTask = await startGatedScan(scanner: mock, gate: gate)
        mock.simulateServiceFound(service)
        mock.simulateServiceFound(service)
        mock.simulateServiceFound(service)
        gate.close()

        let discovered = await runTask.value
        #expect(discovered.count == 1)
    }

    @Test("`run` honors `didRemove` — removed services don't appear in the returned array")
    func runHonorsRemoveCallbacks() async {
        let mock = MockBonjourServiceScanner()
        let gate = ScanWindowGate()
        let staying = makeService(name: "Persistent")
        let leaving = makeService(name: "Transient")

        let runTask = await startGatedScan(scanner: mock, gate: gate)
        mock.simulateServiceFound(staying)
        mock.simulateServiceFound(leaving)
        mock.simulateServiceLost(leaving)
        gate.close()

        let discovered = await runTask.value
        #expect(discovered.count == 1)
        #expect(discovered.first?.id == staying.id)
    }

    @Test("`run` honors `didReset` — clears collected services if the scanner resets mid-window")
    func runHonorsResetCallbacks() async {
        let mock = MockBonjourServiceScanner()
        let gate = ScanWindowGate()
        let beforeReset = makeService(name: "Before")
        let afterReset = makeService(name: "After")

        let runTask = await startGatedScan(scanner: mock, gate: gate)
        mock.simulateServiceFound(beforeReset)
        mock.simulateReset()
        mock.simulateServiceFound(afterReset)
        gate.close()

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
        let gate = ScanWindowGate()
        let service = makeService(name: "Resilient")

        let runTask = await startGatedScan(scanner: mock, gate: gate)
        mock.simulateServiceFound(service)
        mock.simulateError("transient network failure")
        gate.close()

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
