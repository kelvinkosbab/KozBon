//
//  WhatsNewView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourStorage

// MARK: - HighlightInsight

/// Identifies which release summary the user long-pressed so
/// `.sheet(item:)` can present an AI explanation of what that
/// release means for them. `id` is per-tap (a fresh `UUID`) rather
/// than the text, so long-pressing the same summary twice in a row
/// still re-presents the sheet.
private struct HighlightInsight: Identifiable {
    let id = UUID()
    let version: String
    let text: String
}

// MARK: - WhatsNewView

/// Read-only page surfacing one section per release since the 3.0
/// baseline. Pushed onto the navigation stack from the
/// `SettingsView` About section.
///
/// The release data is the shared ``ReleaseNotes/all`` table in
/// `BonjourCore` — the same source of truth the AI chat assistant
/// reads, so the "What's New" page and the assistant's answers
/// can never drift apart.
///
/// Each release shows a short summary rather than its full change
/// list. The summary long-presses (or, for VoiceOver, exposes an
/// accessibility action) into an AI "what this means for you"
/// insight via the shared ``ServiceExplanationSheet`` — the same
/// Insights surface the Discover and Library rows use, routed
/// through whichever AI backend the user has selected.
struct WhatsNewView: View {

    @Environment(\.preferencesStore) private var preferencesStore
    @State private var insightTarget: HighlightInsight?

    var body: some View {
        List {
            ForEach(ReleaseNotes.all) { release in
                Section {
                    summaryRow(version: release.version, summary: release.summary)
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
        // Inherits the Preferences palette from the pushing
        // `NavigationStack`.
        .ambientMeshBackground()
        .navigationTitle(String(localized: Strings.Settings.whatsNew))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .accessibilityIdentifier("whats_new_list")
        // Insights sheet — gated on FoundationModels + iOS 26 the
        // same way the service-type Insights are. Cloud backends
        // also flow through `ServiceExplanationSheet`, which is
        // 26-only, so release insights match the existing
        // availability behavior exactly.
        #if canImport(FoundationModels)
        .modifier(WhatsNewInsightSheetModifier(target: $insightTarget))
        #endif
    }

    // MARK: - Summary Row

    /// One release's summary. When AI analysis is enabled, the row
    /// gains a long-press Insights menu and a matching VoiceOver
    /// action; when disabled, it's a plain read-only row (no empty
    /// context menu).
    ///
    /// Displays the translated summary but hands the English one to
    /// the Insights sheet: the explainers answer in the user's
    /// language anyway, and the English is the authored source.
    @ViewBuilder
    private func summaryRow(version: String, summary: String) -> some View {
        let row = Text(verbatim: Strings.Settings.releaseSummary(summary))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 4)

        if preferencesStore.aiAnalysisEnabled {
            row
                .contextMenu {
                    // Backend-aware (ADR 0005): renders the on-device
                    // "Explain with AI", a cloud "Explain with
                    // Claude/GitHub", or a sign-in CTA — the same
                    // affordance the service rows use. Fires the
                    // selection haptic itself.
                    InsightsContextMenuItems(action: {
                        insightTarget = HighlightInsight(version: version, text: summary)
                    })
                }
                // Context menus aren't reachable via VoiceOver's
                // rotor, so mirror the Insights action explicitly.
                .accessibilityActions {
                    InsightsAccessibilityAction(action: {
                        insightTarget = HighlightInsight(version: version, text: summary)
                    })
                }
        } else {
            row
        }
    }
}

// MARK: - Insight Sheet Modifier

#if canImport(FoundationModels)

/// Presents ``ServiceExplanationSheet`` for the long-pressed
/// release summary.
private struct WhatsNewInsightSheetModifier: ViewModifier {

    @Binding var target: HighlightInsight?

    func body(content: Content) -> some View {
        content.sheet(item: $target) { insight in
            ServiceExplanationSheet(
                releaseHighlight: insight.text,
                version: insight.version
            )
        }
    }
}

#endif
