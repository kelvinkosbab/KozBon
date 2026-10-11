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
/// row that opens the Shortcuts app, and a few automations to try.
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
            if let url = URL(string: "shortcuts://") {
                Section {
                    Link(destination: url) {
                        HStack {
                            Text(Strings.ShortcutsGuide.openShortcuts)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image.externalLink
                                .foregroundStyle(.secondary)
                                .imageScale(.medium)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityIdentifier("shortcuts_guide.link")
                }
            }

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
        }
        // Inherits the Preferences palette from the pushing
        // `NavigationStack`.
        .ambientMeshBackground()
        .navigationTitle(String(localized: Strings.Settings.usingShortcuts))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("shortcuts_guide_list")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShortcutsGuideView()
    }
}
#endif
