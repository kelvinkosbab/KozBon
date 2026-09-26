//
//  View+AmbientMeshBackground.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourStorage

// MARK: - Environment

extension EnvironmentValues {

    /// The ambient palette in force for this part of the view tree.
    ///
    /// Each tab's root container declares its palette with
    /// ``SwiftUICore/View/ambientMeshPalette(_:)``; everything
    /// pushed inside that container — detail pages included —
    /// inherits it, so a detail screen is always washed in the
    /// colour of the tab the user came from rather than in a
    /// palette hardcoded at its own call site.
    @Entry var ambientMeshPalette: AmbientMeshPalette = .discover
}

// MARK: - View + ambientMeshBackground

extension View {

    /// Declares the ambient palette for this subtree.
    ///
    /// Apply at a tab's root container (its `NavigationStack` /
    /// `NavigationSplitView`) so pushed destinations inherit it.
    ///
    /// - Parameter palette: The tab's colour scheme.
    func ambientMeshPalette(_ palette: AmbientMeshPalette) -> some View {
        environment(\.ambientMeshPalette, palette)
    }

    /// Paints ``AmbientMeshBackground`` behind a scrollable
    /// container in the inherited palette, hiding the container's
    /// own background so the wash shows through its margins.
    ///
    /// Applies nothing at all when the wash is suppressed, so the
    /// container keeps the platform's default styling rather than
    /// being left transparent over a hidden background.
    ///
    /// - Parameter intensity: How strongly the wash reads. Pass
    ///   ``AmbientMeshIntensity/subdued`` on a placeholder column
    ///   that shares a wide window with a standard-intensity
    ///   surface.
    func ambientMeshBackground(
        intensity: AmbientMeshIntensity = .standard
    ) -> some View {
        modifier(AmbientMeshBackgroundModifier(intensity: intensity))
    }
}

// MARK: - AmbientMeshBackgroundModifier

/// Decides whether the ambient wash is drawn, and mounts it if so.
///
/// The decision lives here rather than inside
/// ``AmbientMeshBackground`` because turning the wash off has to also
/// leave `scrollContentBackground` alone — a view that renders
/// `Color.clear` behind a list whose own background is hidden isn't
/// the default styling, it's a transparent list.
struct AmbientMeshBackgroundModifier: ViewModifier {

    /// How strongly the wash reads on this surface.
    let intensity: AmbientMeshIntensity

    @Environment(\.ambientMeshPalette) private var palette
    @Environment(\.preferencesStore) private var preferencesStore

    /// Increase Contrast is a legibility request; any tint behind
    /// the content works against it.
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    /// Reduce Transparency asks for opaque backgrounds. The wash is
    /// a translucent layer over the window, which is the thing that
    /// setting exists to remove.
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Smart Invert inverts everything not opted out, turning a cool
    /// blue wash into a hot orange one behind inverted text. Opting
    /// out would keep the wash uninverted against inverted content,
    /// which is worse — so drop it instead.
    @Environment(\.accessibilityInvertColors) private var invertColors

    func body(content: Content) -> some View {
        if isSuppressed {
            content
        } else {
            content
                .scrollContentBackground(.hidden)
                .background {
                    AmbientMeshBackground(palette: palette, intensity: intensity)
                }
        }
    }

    /// The accessibility settings take precedence over the
    /// preference: a user who asked the system for higher contrast
    /// shouldn't have to find this app's toggle as well.
    private var isSuppressed: Bool {
        !preferencesStore.ambientBackgroundEnabled
            || colorSchemeContrast == .increased
            || reduceTransparency
            || invertColors
    }
}
