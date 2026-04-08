//
//  ServiceTypeBadge.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourModels

// MARK: - ServiceTypeBadge

/// A capsule-shaped badge displaying a Bonjour service type's icon and optionally its name.
///
/// Used in toolbars and list rows to visually identify a service type. Adapts its label
/// style based on the provided ``Style``.
public struct ServiceTypeBadge: View {

    let serviceType: BonjourServiceType
    let style: Style

    /// Creates a service type badge.
    ///
    /// - Parameters:
    ///   - serviceType: The service type whose icon and name to display.
    ///   - style: Controls whether the badge shows the icon only, title and icon, or adapts based on size class.
    public init(serviceType: BonjourServiceType, style: Style) {
        self.serviceType = serviceType
        self.style = style
    }

    public var body: some View {
        HStack {
            Label(serviceType.name, systemImage: serviceType.imageSystemName)
                .modifier(LabelStyleModifier(style: style))
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

    /// Controls the label presentation style of the badge.
    public enum Style {
        /// Displays both the service type name and icon.
        case titleAndIcon
        /// Displays only the icon.
        case iconOnly
        /// Displays the title and icon on regular size class, icon only on compact.
        case basedOnSizeClass
    }

    // MARK: - LabelStyleModifier

    private struct LabelStyleModifier: ViewModifier {

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
