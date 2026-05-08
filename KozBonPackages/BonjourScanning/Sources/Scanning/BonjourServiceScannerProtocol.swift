//
//  BonjourServiceScannerProtocol.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - BonjourServiceScannerProtocol

/// Protocol defining the interface for discovering Bonjour services on the local network.
///
/// Conforming types manage the discovery lifecycle — starting and stopping scans — and
/// report results through a ``BonjourServiceScannerDelegate``.
@MainActor
public protocol BonjourServiceScannerProtocol: AnyObject, Sendable {

    /// Delegate that receives service discovery updates and errors.
    var delegate: BonjourServiceScannerDelegate? { get set }

    /// Whether the scanner is currently searching for services or resolving addresses.
    var isProcessing: Bool { get }

    /// Begins scanning for all configured Bonjour service types.
    ///
    /// - Parameter publishedServices: Services currently being published by the user,
    ///   so the scanner can also discover their types on the network.
    func startScan(publishedServices: Set<BonjourService>)

    /// Stops all active scanning operations.
    func stopScan()
}

// MARK: - BonjourServiceScanner + Protocol Conformance

extension BonjourServiceScanner: BonjourServiceScannerProtocol {}
