//
//  ServiceEntity.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(visionOS)

import RealityKit
import SwiftUI

// MARK: - ServiceEntity

/// Creates and configures RealityKit entities representing discovered Bonjour services.
@MainActor
enum ServiceEntity {

    // MARK: - Hub Entity

    /// Creates the central hub entity representing the local device.
    static func makeHub() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.04)
        let material = SimpleMaterial(
            color: UIColor(Color.kozBonBlue),
            roughness: 0.3,
            isMetallic: true
        )
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "hub"
        entity.components.set(InputTargetComponent())
        entity.generateCollisionShapes(recursive: false)
        return entity
    }

    // MARK: - Service Sphere

    /// Creates a sphere entity for a discovered service.
    ///
    /// - Parameters:
    ///   - service: The Bonjour service to represent.
    ///   - index: Position index for circular layout.
    ///   - total: Total number of services for layout calculation.
    ///   - radius: Distance from center hub.
    /// - Returns: A configured `ModelEntity` positioned in a circle.
    static func makeSphere(
        for service: BonjourService,
        index: Int,
        total: Int,
        radius: Float = 0.25
    ) -> ModelEntity {
        let sphereRadius: Float = 0.025
        let mesh = MeshResource.generateSphere(radius: sphereRadius)

        let color: UIColor = service.serviceType.transportLayer.isTcp
            ? UIColor(Color.kozBonBlue.opacity(0.8))
            : UIColor(.green.opacity(0.8))

        let material = SimpleMaterial(
            color: color,
            roughness: 0.2,
            isMetallic: true
        )

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "service-\(service.id)"

        let angle = (Float(index) / Float(max(total, 1))) * .pi * 2
        entity.position = SIMD3<Float>(
            cos(angle) * radius,
            0,
            sin(angle) * radius
        )

        entity.components.set(InputTargetComponent())
        entity.generateCollisionShapes(recursive: false)

        return entity
    }

    // MARK: - Connection Line

    /// Creates a thin cylinder connecting the hub to a service sphere.
    static func makeConnection(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>
    ) -> ModelEntity {
        let direction = end - start
        let distance = length(direction)

        let mesh = MeshResource.generateCylinder(height: distance, radius: 0.002)
        let material = SimpleMaterial(
            color: UIColor(.white.opacity(0.3)),
            roughness: 0.5,
            isMetallic: false
        )

        let entity = ModelEntity(mesh: mesh, materials: [material])

        let midpoint = (start + end) / 2
        entity.position = midpoint

        if distance > 0.001 {
            let normalizedDirection = normalize(direction)
            let up = SIMD3<Float>(0, 1, 0)

            if abs(dot(normalizedDirection, up)) < 0.999 {
                entity.look(at: end, from: midpoint, relativeTo: nil)
                entity.transform.rotation *= simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
            }
        }

        return entity
    }

    // MARK: - Text Label

    /// Creates a floating text label entity.
    static func makeLabel(
        text: String,
        position: SIMD3<Float>,
        offset: SIMD3<Float> = SIMD3<Float>(0, 0.05, 0)
    ) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.015),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )

        let material = SimpleMaterial(
            color: .white,
            roughness: 0.5,
            isMetallic: false
        )

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position + offset

        let bounds = entity.visualBounds(relativeTo: nil)
        let centerOffset = -bounds.center
        entity.position += centerOffset
        entity.position.y = position.y + offset.y

        return entity
    }
}

#endif
