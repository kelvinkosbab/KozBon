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

    /// Locks the capsule's height to a fixed value so badges in
    /// adjacent list rows line up regardless of which SF Symbol is
    /// rendered inside. SF Symbols have different intrinsic
    /// bounding-box ratios — `homekit` is short and wide, `printer.fill`
    /// is closer to square, `terminal` is square — and without this
    /// frame the rows render at slightly different heights, which
    /// reads as "ragged" against the otherwise tidy list. Wrapping
    /// the value in `@ScaledMetric` lets the badge grow with the
    /// user's Dynamic Type setting instead of capping at a hard
    /// pixel count.
    @ScaledMetric private var badgeHeight: CGFloat = 30

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
                // Pin the SF Symbol size to the body font's cap-height.
                // Without an explicit font, `Label` inherits whatever
                // ambient style the parent List/Form applies, which
                // varies by platform — explicit body keeps every badge
                // the same regardless of where it's embedded.
                .font(.body)
                .padding(.horizontal)
        }
        .frame(height: badgeHeight)
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
        // `.hoverEffect` is unavailable on macOS — AppKit handles
        // pointer-hover through its native control styling. Limit the
        // modifier to the platforms where it actually exists.
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
