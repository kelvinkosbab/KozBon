//
//  BonjourServiceScannerProtocol.swift
//  KozBon
//
//  Created by Dependency Injection Implementation
//  Copyright © 2024 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceScannerProtocol

/// Protocol defining the interface for scanning Bonjour services
@MainActor
protocol BonjourServiceScannerProtocol: AnyObject, Sendable {
    var delegate: BonjourServiceScannerDelegate? { get set }
    var isProcessing: Bool { get }
    
    func startScan()
    func stopScan()
}

// MARK: - BonjourServiceScanner + Protocol Conformance

extension BonjourServiceScanner: BonjourServiceScannerProtocol {}
