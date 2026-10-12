//
//  ShortcutsGuideView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(iOS)
import SwiftUI
import BonjourLocalization

// MARK: - ShortcutsGuideView

/// The "Using KozBon with Shortcuts" page pushed from Settings: a
/// few automations to try, then a row that opens the Shortcuts app.
///
/// A plain link rather than Apple's `ShortcutsLink` button, which
/// looked out of place in the list. The trade-off is that it opens
/// the Shortcuts app's main screen, not KozBon's actions.
struct ShortcutsGuideView: View {

    private struct Idea: Identifiable {
        let id: String
        let title: LocalizedStringResource
        let detail: LocalizedStringResource
    }

    private static let ideas: [Idea] = [
        Idea(
            id: "morning",
            title: Strings.ShortcutsGuide.morningTitle,
            detail: Strings.ShortcutsGuide.morningDetail
        ),
        Idea(
            id: "offline",
            title: Strings.ShortcutsGuide.offlineTitle,
            detail: Strings.ShortcutsGuide.offlineDetail
        ),
        Idea(
            id: "broadcast",
            title: Strings.ShortcutsGuide.broadcastTitle,
            detail: Strings.ShortcutsGuide.broadcastDetail
        )
    ]

    var body: some View {
        List {
            Section {
                ForEach(Self.ideas) { idea in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(idea.title)
                            .font(.headline)
                        Text(idea.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text(Strings.ShortcutsGuide.ideas)
                    .accessibilityAddTraits(.isHeader)
            }

            if let url = URL(string: "shortcuts://") {
                Section {
                    Link(destination: url) {
                        OpenShortcutsLabel()
                    }
                    .accessibilityIdentifier("shortcuts_guide.link")
                }
            }
        }
        // Inherits the Preferences palette from the pushing
        // `NavigationStack`.
        .ambientMeshBackground()
        .navigationTitle(String(localized: Strings.Settings.usingShortcuts))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("shortcuts_guide_list")
    }
}

// MARK: - OpenShortcutsLabel

/// The "Open Shortcuts" row: a small tile in the Shortcuts app icon's
/// colours, and a title that takes the same gradient over the ambient
/// wash.
///
/// Its own view so it reads `isAmbientMeshShowing` from inside the
/// list the wash is mounted on, not from the page above it.
private struct OpenShortcutsLabel: View {

    /// The Shortcuts app icon's pink → purple → blue.
    private static let shortcutsColors: [Color] = [
        Color(hex: 0xF2557A),
        Color(hex: 0xA25CE6),
        Color(hex: 0x4A6CF2)
    ]

    @Environment(\.isAmbientMeshShowing) private var isAmbientMeshShowing
    @ScaledMetric(relativeTo: .body) private var tileSize = 28.0

    var body: some View {
        HStack {
            Label {
                Text(Strings.ShortcutsGuide.openShortcuts)
                    .foregroundStyle(titleStyle)
            } icon: {
                Image.shortcuts
                    .font(.system(size: tileSize * 0.55, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: tileSize, height: tileSize)
                    .background(
                        LinearGradient(
                            colors: Self.shortcutsColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: .rect(cornerRadius: tileSize * 0.225, style: .continuous)
                    )
                    .accessibilityHidden(true)
            }
            Spacer()
            Image.externalLink
                .foregroundStyle(.secondary)
                .imageScale(.medium)
                .accessibilityHidden(true)
        }
    }

    private var titleStyle: AnyShapeStyle {
        guard isAmbientMeshShowing else { return AnyShapeStyle(.primary) }
        return AnyShapeStyle(
            LinearGradient(colors: Self.shortcutsColors, startPoint: .leading, endPoint: .trailing)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShortcutsGuideView()
    }
}
#endif
