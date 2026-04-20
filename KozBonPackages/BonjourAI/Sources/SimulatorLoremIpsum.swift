//
//  SimulatorLoremIpsum.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if targetEnvironment(simulator)

import Foundation

// MARK: - SimulatorLoremIpsum

/// Generates random 2-6 sentence lorem ipsum blocks for use in the iOS simulator,
/// where Apple Intelligence is not available for real on-device AI responses.
enum SimulatorLoremIpsum {

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

    /// Returns a random lorem ipsum response containing between 2 and 6 sentences.
    static func randomResponse() -> String {
        let count = Int.random(in: 2...6)
        return (0..<count)
            .map { _ in sentences.randomElement() ?? sentences[0] }
            .joined(separator: " ")
    }

    /// Returns a random lorem ipsum Markdown-formatted response with a heading and bullets,
    /// mimicking the structure of real AI responses for more realistic testing.
    static func randomMarkdownResponse() -> String {
        let intro = randomResponse()
        let bulletCount = Int.random(in: 2...4)
        let bullets = (0..<bulletCount)
            .map { _ in "- " + (sentences.randomElement() ?? sentences[0]) }
            .joined(separator: "\n")

        return """
            ## Overview
            \(intro)

            ## Key points
            \(bullets)
            """
    }
}

#endif
