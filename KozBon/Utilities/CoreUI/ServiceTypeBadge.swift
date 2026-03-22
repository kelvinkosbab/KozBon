//
//  ServiceTypeBadge.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - ServiceTypeBadge

struct ServiceTypeBadge: View {

    let serviceType: BonjourServiceType
    let style: Style

    var body: some View {
        HStack {
            Label(serviceType.name, systemImage: serviceType.imageSystemName)
                .modifier(LabelStyle(style: style))
                .padding(.vertical, 6)
                .padding(.horizontal)
        }
        #if os(visionOS)
        .glassBackgroundEffect()
        .clipShape(.capsule)
        #else
        .background(
            Color.kozBonBlue
                .opacity(0.4)
        )
        .clipShape(.capsule)
        #endif
        .accessibilityElement(children: .combine)
        .accessibilityLabel(serviceType.name)
        #if os(iOS) || os(visionOS)
        .hoverEffect(.lift)
        #endif
    }

    // MARK: - Style

    enum Style {
        case titleAndIcon
        case iconOnly
        case basedOnSizeClass
    }

    // MARK: - LabelStyle

    private struct LabelStyle: ViewModifier {

        @Environment(\.horizontalSizeClass) var horizontalSizeClass

        let style: Style

        func body(content: Content) -> some View {
            switch style {
            case .titleAndIcon:
                content.labelStyle(.titleAndIcon)

            case .iconOnly:
                content.labelStyle(.iconOnly)

            case .basedOnSizeClass:
                if horizontalSizeClass == .regular {
                    content
                        .labelStyle(.titleAndIcon)
                } else {
                    content
                        .labelStyle(.iconOnly)
                }
            }
        }
    }
}
