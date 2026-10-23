//
//  SettingsView+About.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization

// MARK: - SettingsView + About Section

extension SettingsView {

    /// Build metadata — marketing version row, a navigation row
    /// that pushes the "What's New" release-notes page, and a link
    /// to the open-source repository.
    @ViewBuilder
    var aboutSection: some View {
        Section {
            LabeledContent(
                String(localized: Strings.Settings.version),
                value: AppVersion.marketing
            )
            // `monospacedDigit()` keeps the value column aligned
            // against any neighbouring rows we add later.
            .monospacedDigit()
            .accessibilityElement(children: .combine)

            NavigationLink {
                WhatsNewView()
            } label: {
                Text(Strings.Settings.whatsNew)
            }
            .accessibilityHint(Strings.Accessibility.whatsNewHint)
            .accessibilityIdentifier("whats_new_link")

            Link(destination: Constants.Links.sourceRepository) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        // Same wording as the macOS Help menu item.
                        Text(Strings.Help.kozbonOnGitHub)
                        // `Color.primary`, not `.primary`: inside a `Link`
                        // the hierarchical style takes the link's tint.
                        Text(Strings.Settings.openSourceLicense)
                            .font(.caption)
                            .foregroundStyle(Color.primary)
                    }
                    Spacer()
                    // Marks the row as leaving the app, where the
                    // What's New row above shows a push chevron.
                    ExternalLinkIndicator()
                }
            }
            .accessibilityHint(Strings.Accessibility.sourceCodeHint)
            .accessibilityIdentifier("source_code_link")
        } header: {
            Text(Strings.Settings.about)
                .accessibilityAddTraits(.isHeader)
        }
    }
}
