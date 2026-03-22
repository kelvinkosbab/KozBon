//
//  NetworkTopologyView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(visionOS)

import RealityKit
import SwiftUI

// MARK: - NetworkTopologyView

/// A volumetric 3D view that displays discovered Bonjour services as spheres
/// orbiting around a central hub entity representing the local device.
struct NetworkTopologyView: View {

    @StateObject private var viewModel = BonjourServicesViewModel(
        serviceScanner: BonjourServiceScanner.shared
    )

    @State private var selectedServiceName: String?

    var body: some View {
        ZStack {
            RealityView { content in
                let rootEntity = Entity()
                rootEntity.name = "networkRoot"
                content.add(rootEntity)

                let hub = ServiceEntity.makeHub()
                rootEntity.addChild(hub)

                let hubLabel = ServiceEntity.makeLabel(
                    text: "This Device",
                    position: .zero,
                    offset: SIMD3<Float>(0, 0.06, 0)
                )
                rootEntity.addChild(hubLabel)

            } update: { content in
                guard let rootEntity = content.entities.first(where: { $0.name == "networkRoot" }) else {
                    return
                }

                removeOldServiceEntities(from: rootEntity)
                addServiceEntities(to: rootEntity)
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        let name = value.entity.name
                        if name.hasPrefix("service-") {
                            let serviceId = String(name.dropFirst("service-".count))
                            selectedServiceName = serviceId
                        }
                    }
            )

            if let selectedServiceName {
                VStack {
                    Spacer()
                    Text("Selected: \(selectedServiceName)")
                        .font(.headline)
                        .padding()
                        .glassBackgroundEffect()
                        .onTapGesture {
                            self.selectedServiceName = nil
                        }
                }
                .padding()
            }
        }
        .task {
            viewModel.load()
        }
        .onDisappear {
            viewModel.serviceScanner.stopScan()
        }
    }

    // MARK: - Entity Management

    private func removeOldServiceEntities(from root: Entity) {
        let existingServiceIds = Set(
            viewModel.sortedActiveServices.map { "service-\($0.id)" }
        )

        for child in root.children where child.name.hasPrefix("service-") || child.name.hasPrefix("connection-") || child.name.hasPrefix("label-") {
            let baseName = child.name
                .replacingOccurrences(of: "connection-", with: "service-")
                .replacingOccurrences(of: "label-", with: "service-")
            if !existingServiceIds.contains(baseName) {
                child.removeFromParent()
            }
        }
    }

    private func addServiceEntities(to root: Entity) {
        let services = viewModel.sortedActiveServices
        let total = services.count

        for (index, service) in services.enumerated() {
            let entityName = "service-\(service.id)"

            guard root.children.first(where: { $0.name == entityName }) == nil else {
                continue
            }

            let sphere = ServiceEntity.makeSphere(
                for: service,
                index: index,
                total: total
            )
            root.addChild(sphere)

            let connection = ServiceEntity.makeConnection(
                from: .zero,
                to: sphere.position
            )
            connection.name = "connection-\(service.id)"
            root.addChild(connection)

            let label = ServiceEntity.makeLabel(
                text: service.service.name,
                position: sphere.position
            )
            label.name = "label-\(service.id)"
            root.addChild(label)
        }
    }
}

#endif
