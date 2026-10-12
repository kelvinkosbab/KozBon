//
//  SiriPhraseRow.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICore
import BonjourLocalization

// MARK: - SiriPhraseRow

/// A list row, used in Settings and on Discover, that keeps "Ask Siri"
/// fixed and cycles through Siri phrases beneath it.
struct SiriPhraseRow: View {

    let phrases: [LocalizedStringResource]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var index = 0

    private static let interval: Duration = .seconds(3)

    var body: some View {
        HStack(spacing: 12) {
            Image.siri
                .font(.title2)
                .foregroundStyle(appleIntelligenceStyle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Settings.askSiri)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(appleIntelligenceStyle)

                ZStack(alignment: .leading) {
                    // Every phrase laid out invisibly so the row is as
                    // tall as the longest one and doesn't jump as they
                    // change.
                    ForEach(phrases.indices, id: \.self) { phraseIndex in
                        Text(phrases[phraseIndex]).hidden()
                    }

                    if phrases.indices.contains(index) {
                        Text(phrases[index])
                            .id(index)
                            .transition(reduceMotion ? .opacity : .push(from: .bottom))
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
            }
        }
        .padding(.vertical, 4)
        // The phrases change on a timer, so VoiceOver reads them all at
        // once instead of whichever one happens to be showing.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Strings.Settings.askSiri))
        .accessibilityValue(phrases.map { String(localized: $0) }.formatted(.list(type: .or)))
        .accessibilityIdentifier("siriPhrases")
        .task { await cycle() }
    }

    /// The Apple Intelligence gradient the Insights button uses, or
    /// its solid accent under Increase Contrast, where the lighter
    /// stops don't hold contrast.
    private var appleIntelligenceStyle: AnyShapeStyle {
        if colorSchemeContrast == .increased {
            return AnyShapeStyle(AIBackend.appleIntelligence.accentColor)
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: AmbientMeshPalette.chatAccents(for: .appleIntelligence),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private func cycle() async {
        guard phrases.count > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: Self.interval)
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.5)) {
                index = (index + 1) % phrases.count
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Form {
        Section {
            SiriPhraseRow(phrases: Strings.Settings.siriPhrases)
        }
    }
}
