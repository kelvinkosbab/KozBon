//
//  ShortcutsGuideView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(iOS)
import AppIntents
import SwiftUI
import BonjourLocalization

// MARK: - ShortcutsGuideView

/// The "Using KozBon with Shortcuts" page pushed from Settings: what
/// the actions are for, Apple's button that opens KozBon's own page
/// in the Shortcuts app, and a few automations to try.
///
/// A plain `shortcuts://` link can only open the Shortcuts app's
/// main screen; `ShortcutsLink` is the one way to land on KozBon's
/// actions.
struct ShortcutsGuideView: View {

    private struct Idea: Identifiable {
        let id: String
        let title: LocalizedStringResource
        let detail: LocalizedStringResource
    }

    private static let ideas: [Idea] = [
        Idea(
            id: "morning",
            title: Strings.Settings.shortcutsIdeaMorningTitle,
            detail: Strings.Settings.shortcutsIdeaMorningDetail
        ),
        Idea(
            id: "offline",
            title: Strings.Settings.shortcutsIdeaOfflineTitle,
            detail: Strings.Settings.shortcutsIdeaOfflineDetail
        ),
        Idea(
            id: "broadcast",
            title: Strings.Settings.shortcutsIdeaBroadcastTitle,
            detail: Strings.Settings.shortcutsIdeaBroadcastDetail
        )
    ]

    var body: some View {
        List {
            Section {
                Text(Strings.Settings.shortcutsIntro)

                ShortcutsLink()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("shortcuts_guide.link")
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
                Text(Strings.Settings.shortcutsIdeas)
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
