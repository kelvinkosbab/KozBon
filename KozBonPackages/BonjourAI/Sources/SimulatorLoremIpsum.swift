//
//  SimulatorLoremIpsum.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if targetEnvironment(simulator)

import Foundation

// MARK: - SimulatorLoremIpsum

/// Generates random lorem ipsum blocks of varying lengths for use in the iOS
/// simulator, where Apple Intelligence isn't available for real on-device AI
/// responses. The simulator chat session picks a `Size` at random per turn so
/// developers can see how the chat surface handles short replies, sprawling
/// multi-section responses, and everything between — long-content layouts
/// (scroll-pinning, streaming-driven autoscroll, sentence haptics) only show
/// up under realistic length variance.
enum SimulatorLoremIpsum {

    /// Buckets of response length the generator can return. Each maps to a
    /// rough token-count target so the streaming UI gets exercised across the
    /// short / medium / long / very-long axes a real model would produce.
    ///
    /// The buckets are weighted toward "medium" in ``randomSize()`` because
    /// that's the most common production response length — but every
    /// non-trivial regression in the chat layout (e.g. "the user's question
    /// scrolls off-screen during a 600-word reply") needs an `xlarge`
    /// response to surface, so all four buckets fire eventually.
    enum Size: CaseIterable {
        case small
        case medium
        case large
        case xlarge

        /// Number of intro sentences for this size.
        fileprivate var sentenceCount: ClosedRange<Int> {
            switch self {
            case .small: return 1...2
            case .medium: return 2...4
            case .large: return 4...6
            case .xlarge: return 8...12
            }
        }

        /// Number of bullets in the "Key points" section. Returns `nil` for
        /// `.small`, which omits the section entirely so single-paragraph
        /// replies are exercised too.
        fileprivate var bulletCount: ClosedRange<Int>? {
            switch self {
            case .small: return nil
            case .medium: return 2...3
            case .large: return 3...5
            case .xlarge: return 5...7
            }
        }

        /// Whether this size renders an extra "Considerations" section after
        /// the bullets. Only `.xlarge` does — small/medium/large stay focused
        /// to mimic the response-length preference scaling in production.
        fileprivate var includesConsiderations: Bool {
            self == .xlarge
        }
    }

    /// A pool of lorem ipsum sentences that get randomly selected.
    private static let sentences: [String] = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
        "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore.",
        "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt.",
        "Curabitur pretium tincidunt lacus, nulla gravida orci a odio.",
        "Nullam varius, turpis et commodo pharetra, est eros bibendum elit.",
        "Aliquam erat volutpat. Nunc eleifend leo vitae magna.",
        "In vulputate aliquam nulla, eget malesuada tellus porta sit amet.",
        "Fusce consectetur, turpis nec venenatis pulvinar, ligula mi ultricies neque.",
        "Phasellus gravida semper nisi. Nullam vel sem.",
        "Pellentesque libero tortor, tincidunt et, tincidunt eget, semper nec, quam.",
        "Sed hendrerit. Maecenas malesuada. Praesent congue erat at massa.",
        "Sed cursus turpis vitae tortor. Donec posuere vulputate arcu.",
        "Phasellus accumsan cursus velit. Vestibulum ante ipsum primis in faucibus.",
        "Sed aliquam ultrices mauris. Integer ante arcu, accumsan a, consectetuer eget."
    ]

    /// Returns a randomly-chosen ``Size``. Weighted so that medium/large fire
    /// most often (matching production assistant cadence) while small and
    /// xlarge still appear regularly enough to surface UI bugs that only show
    /// at the extremes.
    static func randomSize() -> Size {
        // Weights: small=2, medium=4, large=3, xlarge=1. Stored as a tiny
        // pool the random selector can index into — clearer than computing
        // cumulative ranges and easier to tune by hand.
        let weighted: [Size] = [
            .small, .small,
            .medium, .medium, .medium, .medium,
            .large, .large, .large,
            .xlarge
        ]
        return weighted.randomElement() ?? .medium
    }

    /// Returns a random lorem ipsum response sized by `size`. Used for the
    /// "Overview" section of the Markdown response and for any caller that
    /// just wants prose without the heading scaffolding.
    static func randomResponse(size: Size = .medium) -> String {
        let count = Int.random(in: size.sentenceCount)
        return (0..<count)
            .map { _ in sentences.randomElement() ?? sentences[0] }
            .joined(separator: " ")
    }

    /// Returns a random lorem ipsum Markdown-formatted response. Picks a
    /// ``Size`` at random when none is supplied, so the simulator chat
    /// session naturally exercises the full short → very-long range across
    /// successive sends.
    ///
    /// - Small responses are a single paragraph (no headings, no bullets).
    /// - Medium and large responses use the classic Overview + Key points layout.
    /// - Extra-large responses add a third Considerations section to stress
    ///   long-form layout (sticky toolbar, scroll-anchor jumps).
    static func randomMarkdownResponse(size: Size? = nil) -> String {
        let resolvedSize = size ?? randomSize()
        let intro = randomResponse(size: resolvedSize)

        guard let bulletRange = resolvedSize.bulletCount else {
            // Small responses — keep them deliberately spare so the single-
            // paragraph layout path gets exercised. No headings, no bullets.
            return intro
        }

        let bulletCount = Int.random(in: bulletRange)
        let bullets = (0..<bulletCount)
            .map { _ in "- " + (sentences.randomElement() ?? sentences[0]) }
            .joined(separator: "\n")

        var output = """
            ## Overview
            \(intro)

            ## Key points
            \(bullets)
            """

        if resolvedSize.includesConsiderations {
            let considerations = randomResponse(size: .medium)
            output += """


                ## Considerations
                \(considerations)
                """
        }

        return output
    }
}

#endif
