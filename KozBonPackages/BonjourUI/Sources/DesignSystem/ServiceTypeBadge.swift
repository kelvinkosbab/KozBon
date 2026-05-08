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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let serviceType: BonjourServiceType
    let style: Style
    let size: Size

    /// Standard list-row dimension. Locks the capsule's width and
    /// height to a fixed value so badges in adjacent list rows line
    /// up regardless of which SF Symbol is rendered inside. SF
    /// Symbols have different intrinsic bounding-box ratios —
    /// `homekit` is short and wide, `printer.fill` is closer to
    /// square, `terminal` is square — and without this frame the
    /// rows render at slightly different heights, which reads as
    /// "ragged" against the otherwise tidy list. Wrapping the value
    /// in `@ScaledMetric` lets the badge grow with the user's
    /// Dynamic Type setting instead of capping at a hard pixel count.
    @ScaledMetric private var regularDimension: CGFloat = 36

    /// Smaller variant used in navigation bars / toolbars where the
    /// container's vertical budget (~44pt on iOS) doesn't leave the
    /// regular 36pt badge much breathing room. Set to 32pt — larger
    /// than the original 28pt so the SF Symbol (which renders at the
    /// font's line-height, not just cap-height, and is therefore
    /// closer to 22pt at body size) sits comfortably inside the
    /// circle. Apple's own apps follow the same step-down pattern
    /// between list rows and toolbar items.
    @ScaledMetric private var compactDimension: CGFloat = 32

    /// The active dimension based on the selected `size`.
    private var badgeDimension: CGFloat {
        switch size {
        case .regular: regularDimension
        case .compact: compactDimension
        }
    }

    /// Per-size font used by the underlying `Label`. SF Symbols
    /// inherit their rendered size from the surrounding font's
    /// line-height. The compact variant uses `.subheadline` (≈15pt)
    /// so the icon is proportionally smaller than the regular
    /// variant's `.body` (≈17pt) — which keeps the icon-to-circle
    /// ratio roughly consistent across both sizes (~60%) instead of
    /// having the compact icon visually fill its smaller circle.
    private var labelFont: Font {
        switch size {
        case .regular: .body
        case .compact: .subheadline
        }
    }

    /// Creates a service type badge.
    ///
    /// - Parameters:
    ///   - serviceType: The service type whose icon and name to display.
    ///   - style: Controls whether the badge shows the icon only, title and icon, or adapts based on size class.
    ///   - size: Controls the capsule's overall dimension. Defaults to ``Size/regular``
    ///     (36pt) for list rows; pass ``Size/compact`` (28pt) when embedding the badge
    ///     in a navigation bar or toolbar where vertical space is tighter.
    public init(serviceType: BonjourServiceType, style: Style, size: Size = .regular) {
        self.serviceType = serviceType
        self.style = style
        self.size = size
    }

    /// Whether the rendered Label currently shows ONLY the icon
    /// (no title). Drives the badge's width constraint — icon-only
    /// badges get a fixed square shape so adjacent rows align;
    /// title+icon badges grow to fit their text. Resolved here so
    /// the outer `.frame` and the inner `LabelStyleModifier` stay
    /// in lockstep on `.basedOnSizeClass`.
    private var isEffectivelyIconOnly: Bool {
        switch style {
        case .iconOnly: true
        case .titleAndIcon: false
        case .basedOnSizeClass: horizontalSizeClass != .regular
        }
    }

    public var body: some View {
        HStack {
            Label(serviceType.name, systemImage: serviceType.imageSystemName)
                .modifier(LabelStyleModifier(style: style))
                // Pin the SF Symbol size to a known font so it renders
                // consistently regardless of whatever ambient style the
                // parent List/Form/Toolbar applies. The actual font
                // (`.body` for regular, `.subheadline` for compact)
                // varies by `size` so the icon-to-circle ratio stays
                // roughly constant when the circle shrinks for nav-bar
                // use.
                .font(labelFont)
                // Title+icon badges need horizontal breathing room
                // around the text. Icon-only badges are governed
                // entirely by the fixed square frame below — adding
                // padding there would push the content past the
                // frame and cause the icon to clip against the
                // capsule's edge.
                .padding(.horizontal, isEffectivelyIconOnly ? 0 : 16)
        }
        .frame(
            width: isEffectivelyIconOnly ? badgeDimension : nil,
            height: badgeDimension
        )
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

    // MARK: - Size

    /// Controls the badge's overall dimension. The default `.regular`
    /// is intended for list rows; `.compact` is intended for
    /// toolbars and navigation bars whose ~44pt height squeezes the
    /// regular badge.
    public enum Size: Sendable {
        /// 36pt — used for list-row affordances.
        case regular
        /// 28pt — used inside navigation bars and toolbars where the
        /// container vertical budget is tighter than a list row.
        case compact
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
