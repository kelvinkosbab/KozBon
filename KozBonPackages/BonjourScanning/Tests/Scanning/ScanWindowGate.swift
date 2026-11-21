//
//  ScanWindowGate.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ScanWindowGate

/// Stands in for ``BonjourOneShotScanner``'s scan-window wait so a
/// test decides when the window opens and closes, instead of racing
/// a wall-clock timeout.
///
/// The runner calls ``wait(_:)`` only after it has installed its
/// delegate and started the scanner, so once ``waitUntilOpen()``
/// returns, simulated callbacks are guaranteed to reach the runner.
@MainActor
final class ScanWindowGate {

    // MARK: - Properties

    private(set) var requestedDurations: [Duration] = []
    private var isOpen = false
    private var isClosed = false
    private var openWaiters: [CheckedContinuation<Void, Never>] = []
    private var closeWaiter: CheckedContinuation<Void, Never>?

    // MARK: - Runner Side

    /// Pass as the runner's `waitForScanWindow`.
    func wait(_ duration: Duration) async {
        requestedDurations.append(duration)
        isOpen = true
        openWaiters.forEach { $0.resume() }
        openWaiters.removeAll()
        guard !isClosed else { return }
        await withCheckedContinuation { closeWaiter = $0 }
    }

    // MARK: - Test Side

    /// Returns once the runner has started the scanner and is waiting.
    func waitUntilOpen() async {
        guard !isOpen else { return }
        await withCheckedContinuation { openWaiters.append($0) }
    }

    /// Ends the scan window, letting `run` stop the scanner and return.
    func close() {
        isClosed = true
        closeWaiter?.resume()
        closeWaiter = nil
    }
}
