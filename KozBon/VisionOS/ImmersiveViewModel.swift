//
//  ImmersiveViewModel.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(visionOS)

import RealityKit
import SwiftUI

// MARK: - ImmersiveViewModel

/// Manages the state for the immersive network explorer space.
///
/// Bridges Bonjour service scanner data to RealityKit entities, handling
/// add/remove animations and entity lifecycle in the immersive environment.
@MainActor
final class ImmersiveViewModel: ObservableObject, BonjourServiceScannerDelegate {

    // MARK: - Properties

    @Published private(set) var services: [BonjourService] = []
    @Published var selectedService: BonjourService?

    let serviceScanner: BonjourServiceScannerProtocol
    private let arrangementRadius: Float = 1.5
    private let entityHeight: Float = 1.2

    // MARK: - Init

    init(serviceScanner: BonjourServiceScannerProtocol = BonjourServiceScanner.shared) {
        self.serviceScanner = serviceScanner
        self.serviceScanner.delegate = self
    }

    // MARK: - Actions

    func startScanning() {
        guard !serviceScanner.isProcessing else { return }
        serviceScanner.startScan()
    }

    func stopScanning() {
        serviceScanner.stopScan()
    }

    // MARK: - Entity Creation

    /// Creates the root entity containing the central hub and all service entities.
    func createRootEntity() -> Entity {
        let root = Entity()
        root.name = "immersiveRoot"

        let hub = ServiceEntity.makeHub()
        hub.scale = SIMD3<Float>(repeating: 2.0)
        hub.position = SIMD3<Float>(0, entityHeight, -1.0)
        root.addChild(hub)

        let hubLabel = ServiceEntity.makeLabel(
            text: "This Device",
            position: hub.position,
            offset: SIMD3<Float>(0, 0.12, 0)
        )
        hubLabel.name = "hubLabel"
        root.addChild(hubLabel)

        return root
    }

    /// Updates entities in the root to match current service state.
    func updateEntities(in root: Entity) {
        removeStaleEntities(from: root)
        addNewEntities(to: root)
    }

    // MARK: - Entity Management

    private func removeStaleEntities(from root: Entity) {
        let activeIds = Set(services.map { "immersive-\($0.id)" })

        for child in root.children {
            let name = child.name
            guard name.hasPrefix("immersive-") || name.hasPrefix("immersive-conn-") || name.hasPrefix("immersive-label-") else {
                continue
            }

            let baseId = name
                .replacingOccurrences(of: "immersive-conn-", with: "immersive-")
                .replacingOccurrences(of: "immersive-label-", with: "immersive-")

            if !activeIds.contains(baseId) {
                child.removeFromParent()
            }
        }
    }

    private func addNewEntities(to root: Entity) {
        let hubPosition = SIMD3<Float>(0, entityHeight, -1.0)
        let total = services.count

        for (index, service) in services.enumerated() {
            let entityName = "immersive-\(service.id)"
            guard root.children.first(where: { $0.name == entityName }) == nil else {
                continue
            }

            let angle = (Float(index) / Float(max(total, 1))) * .pi * 2
            let position = SIMD3<Float>(
                cos(angle) * arrangementRadius,
                entityHeight + Float.random(in: -0.15...0.15),
                -1.0 + sin(angle) * arrangementRadius
            )

            let sphere = ServiceEntity.makeSphere(
                for: service,
                index: index,
                total: total,
                radius: 0.04
            )
            sphere.name = entityName
            sphere.position = position
            sphere.scale = .zero

            root.addChild(sphere)

            // Animate scale-in
            var transform = sphere.transform
            transform.scale = SIMD3<Float>(repeating: 1.5)
            sphere.move(to: transform, relativeTo: root, duration: 0.5)

            let connection = ServiceEntity.makeConnection(
                from: hubPosition,
                to: position
            )
            connection.name = "immersive-conn-\(service.id)"
            root.addChild(connection)

            let labelText = "\(service.service.name)\n\(service.serviceType.name)"
            let label = ServiceEntity.makeLabel(
                text: labelText,
                position: position,
                offset: SIMD3<Float>(0, 0.08, 0)
            )
            label.name = "immersive-label-\(service.id)"
            root.addChild(label)
        }
    }

    // MARK: - BonjourServiceScannerDelegate

    func didAdd(service: BonjourService) {
        withAnimation {
            let index = services.firstIndex { $0.id == service.id }
            if let index {
                services[index] = service
            } else {
                services.append(service)
            }
        }
    }

    func didRemove(service: BonjourService) {
        withAnimation {
            let index = services.firstIndex { $0.id == service.id }
            if let index {
                services.remove(at: index)
            }
        }
    }

    func didReset() {
        withAnimation {
            services = []
        }
    }
}

#endif
