//
//  SiriPhraseRow.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourLocalization

// MARK: - SiriPhraseRow

/// One Settings row that keeps "Say" fixed and cycles through Siri
/// phrases beneath it, so a single row shows everything the separate
/// Siri tips used to.
struct SiriPhraseRow: View {

    let phrases: [LocalizedStringResource]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private static let interval: Duration = .seconds(3)

    var body: some View {
        HStack(spacing: 12) {
            Image.siri
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Settings.siriSay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

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
        .accessibilityLabel(Text(Strings.Settings.siriSay))
        .accessibilityValue(phrases.map { String(localized: $0) }.formatted(.list(type: .or)))
        .accessibilityIdentifier("settings.siriPhrases")
        .task { await cycle() }
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
