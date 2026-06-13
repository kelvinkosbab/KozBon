//
//  WhatsNewView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization

// MARK: - WhatsNewView

/// Read-only page surfacing one section per release since the 3.0
/// baseline. Pushed onto the navigation stack from the
/// `SettingsView` About section.
///
/// The release data is the shared ``ReleaseNotes/all`` table in
/// `BonjourCore` — the same source of truth the AI chat assistant
/// reads, so the "What's New" page and the assistant's answers
/// can never drift apart.
struct WhatsNewView: View {

    var body: some View {
        List {
            ForEach(ReleaseNotes.all) { release in
                Section {
                    ForEach(release.highlights, id: \.self) { highlight in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(verbatim: "•")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text(verbatim: highlight)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        // Combine the bullet and text into one
                        // VoiceOver element, then pin the label
                        // to the highlight content. `.combine`
                        // alone would still leave the rotor with
                        // a row, but the bullet `Text` could leak
                        // a "bullet" pronunciation on some
                        // VoiceOver versions despite
                        // `.accessibilityHidden(true)` — the
                        // explicit label forecloses that.
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text(verbatim: highlight))
                    }
                } header: {
                    // Visual: bare version string ("4.4" / "3.7")
                    // — pure digits and a dot, no localization
                    // needed and the page title already gives it
                    // context. VoiceOver: explicit "Version 4.4"
                    // phrasing so heading-rotor navigation reads
                    // unambiguously.
                    Text(verbatim: release.version)
                        .font(.headline)
                        .accessibilityLabel(
                            Strings.Accessibility.whatsNewVersionHeader(release.version)
                        )
                        .accessibilityAddTraits(.isHeader)
                }
            }
        }
        .navigationTitle(String(localized: Strings.Settings.whatsNew))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .accessibilityIdentifier("whats_new_list")
    }
}
