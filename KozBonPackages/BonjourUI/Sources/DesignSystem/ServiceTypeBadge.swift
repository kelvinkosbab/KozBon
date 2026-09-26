//
//  ServiceTypeBadge.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourLocalization
import BonjourModels

// MARK: - ServiceTypeBadge

/// A capsule-shaped badge displaying a Bonjour service type's icon and optionally its name.
///
/// Used in toolbars and list rows to visually identify a service type. Adapts its label
/// style based on the provided ``Style``.
public struct ServiceTypeBadge: View {

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let serviceType: BonjourServiceType

    /// Host the service was discovered on, appended to the title
    /// when there's room for it. `nil` keeps the badge to the
    /// service type alone.
    let host: String?

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
    ///   - host: Optional host name to pair with the service type
    ///     ("AirPlay – Living Room"). Only rendered where the badge
    ///     already shows its title, which on ``Style/basedOnSizeClass``
    ///     means regular width — a compact navigation bar has no room
    ///     for it. VoiceOver reads it in every configuration.
    public init(
        serviceType: BonjourServiceType,
        style: Style,
        size: Size = .regular,
        host: String? = nil
    ) {
        self.serviceType = serviceType
        self.style = style
        self.size = size
        self.host = host
    }

    /// The badge's visible text.
    ///
    /// Drops the host at accessibility Dynamic Type sizes: a
    /// navigation bar has one line to work with, and a truncated
    /// "AirPlay – Livin…" is worse than the type alone. VoiceOver
    /// still hears the host via ``accessibilityText``.
    var title: String {
        ServiceBadgeTitle.visible(
            serviceType: serviceType.name,
            host: dynamicTypeSize.isAccessibilitySize ? nil : host
        )
    }

    /// The spoken form — always includes the host, independent of
    /// size class and Dynamic Type, because the value to a VoiceOver
    /// user doesn't depend on how much room the glyph has.
    var accessibilityText: String {
        ServiceBadgeTitle.spoken(serviceType: serviceType.name, host: host)
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
            Label(title, systemImage: serviceType.imageSystemName)
                .modifier(LabelStyleModifier(style: style))
                // Pin the SF Symbol size to a known font so it renders
                // consistently regardless of whatever ambient style the
                // parent List/Form/Toolbar applies. The actual font
                // (`.body` for regular, `.subheadline` for compact)
                // varies by `size` so the icon-to-circle ratio stays
                // roughly constant when the circle shrinks for nav-bar
                // use.
                .font(labelFont)
                // One line in a navigation bar. Without this a long
                // host wraps the capsule to two lines and blows out
                // the bar's height.
                .lineLimit(1)
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
        // Reads the host even when the visible badge is icon-only,
        // so a compact navigation bar still announces which service
        // on which host the screen is about.
        .accessibilityLabel(accessibilityText)
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

// MARK: - Previews

// Use the canvas's Dynamic Type and localization controls to check
// the two adaptive behaviours: at an accessibility size the host
// drops so the capsule stays one line, and under Arabic / Hebrew the
// `Label` mirrors so the icon sits on the trailing edge.

#Preview("Service Type Badge") {
    let airplay = BonjourServiceType.serviceTypeLibrary.first { $0.name.contains("Airplay") }
        ?? BonjourServiceType.serviceTypeLibrary[0]

    VStack(alignment: .leading, spacing: 16) {
        ServiceTypeBadge(serviceType: airplay, style: .titleAndIcon, size: .compact)
        ServiceTypeBadge(
            serviceType: airplay,
            style: .titleAndIcon,
            size: .compact,
            host: "Living Room"
        )
        // A host that repeats the type collapses back to one name.
        ServiceTypeBadge(
            serviceType: airplay,
            style: .titleAndIcon,
            size: .compact,
            host: airplay.name
        )
        ServiceTypeBadge(serviceType: airplay, style: .iconOnly, size: .compact, host: "Living Room")
    }
    .padding()
}

#Preview("Service Type Badge - RTL") {
    // `layoutDirection` is settable, unlike most accessibility
    // environment values, so the mirroring is checkable here rather
    // than only under the RTL pseudolanguage on a device. The icon
    // should sit on the trailing (left) edge and the capsules should
    // align to the right.
    let airplay = BonjourServiceType.serviceTypeLibrary.first { $0.name.contains("Airplay") }
        ?? BonjourServiceType.serviceTypeLibrary[0]

    VStack(alignment: .leading, spacing: 16) {
        ServiceTypeBadge(serviceType: airplay, style: .titleAndIcon, size: .compact)
        ServiceTypeBadge(
            serviceType: airplay,
            style: .titleAndIcon,
            size: .compact,
            host: "Living Room"
        )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .environment(\.layoutDirection, .rightToLeft)
}
