//
//  BonjourPublishManagerProtocol.swift
//  KozBon
//
//  Created by Dependency Injection Implementation
//  Copyright © 2024 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourPublishManagerProtocol

/// Protocol defining the interface for publishing Bonjour services
@MainActor
protocol BonjourPublishManagerProtocol: AnyObject, Sendable {
    var publishedServices: Set<BonjourService> { get }
    
    func publish(
        name: String,
        type: String,
        port: Int,
        domain: String,
        transportLayer: TransportLayer,
        detail: String
    ) async throws -> BonjourService
    
    func publish(service: BonjourService) async throws -> BonjourService
    
    func unPublish(service: BonjourService) async
    
    func unPublishAllServices() async
}

// MARK: - MyBonjourPublishManager + Protocol Conformance

extension MyBonjourPublishManager: BonjourPublishManagerProtocol {}
