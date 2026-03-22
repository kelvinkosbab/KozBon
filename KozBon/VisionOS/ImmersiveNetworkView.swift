//
//  ImmersiveNetworkView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(visionOS)

import RealityKit
import SwiftUI

// MARK: - ImmersiveNetworkView

/// An immersive space view that places discovered Bonjour services as floating
/// 3D entities in the user's real environment, arranged in a circular pattern
/// around a central hub representing the local device.
struct ImmersiveNetworkView: View {

    @StateObject private var viewModel = ImmersiveViewModel()
    @State private var selectedServiceName: String?

    var body: some View {
        RealityView { content, _ in
            let root = viewModel.createRootEntity()
            content.add(root)
        } update: { content, _ in
            guard let root = content.entities.first(where: { $0.name == "immersiveRoot" }) else {
                return
            }
            viewModel.updateEntities(in: root)
        } attachments: {
            if let selectedServiceName {
                Attachment(id: "serviceDetail") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedServiceName)
                            .font(.headline)
                        Text("Tap to dismiss")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .glassBackgroundEffect()
                    .onTapGesture {
                        self.selectedServiceName = nil
                    }
                }
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    let name = value.entity.name
                    if name.hasPrefix("immersive-") && !name.contains("conn-") && !name.contains("label-") {
                        let serviceId = String(name.dropFirst("immersive-".count))
                        if let service = viewModel.services.first(where: { "\($0.id)" == serviceId }) {
                            selectedServiceName = service.service.name
                        }
                    }
                }
        )
        .task {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }
}

#endif
