//
//  BonjourServiceCategoricalSummary.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - Array<BonjourService> Voice Summary

/// Voice-friendly categorical rollups for a list of discovered
/// services.
///
/// The `Scan…` and `List…` Siri intents both want to tell the
/// user *what kind* of devices they have, not just *how many*.
/// Grouping by the existing ``BonjourServiceCategory`` taxonomy
/// (which already powers the Discover-tab and Library-tab sort
/// filters) keeps the categories consistent with what the user
/// sees in the app.
///
/// Each service is bucketed by its **first matching** category —
/// services overlap several categories in practice (AirPlay is
/// both `appleDevices` and `mediaAndStreaming`), and the first-
/// match rule keeps each service counted once. Services that
/// don't match any predefined category fall into an "other"
/// bucket so the summary always sums to the input count.
public extension Array where Element == BonjourService {

    /// Renders a one-line voice summary describing the
    /// composition of the array.
    ///
    /// Examples:
    /// - `[]` → empty string (caller should branch on this)
    /// - `[airplay]` → "1 Apple device"
    /// - `[airplay, ipp, ssh]` → "1 Apple device, 1 printer, and 1 remote access service"
    /// - `[3× airplay, 2× ipp, 4× http]` → "3 Apple devices, 2 printers, and 4 others"
    @MainActor
    func voiceCategoricalSummary() -> String {
        guard !isEmpty else { return "" }

        // Group each service by the first category that matches.
        // Services not matching any category fall into the
        // sentinel `nil` bucket rendered as "other(s)".
        var bucketCounts: [BonjourServiceCategory?: Int] = [:]
        for service in self {
            let bucket = BonjourServiceCategory.allCases.first { $0.matches(service) }
            bucketCounts[bucket, default: 0] += 1
        }

        // Render in a stable order so the same input produces the
        // same summary across runs. Apple devices and media
        // surface first as the most-recognized categories.
        let renderOrder: [BonjourServiceCategory?] = [
            .appleDevices,
            .mediaAndStreaming,
            .printersAndScanners,
            .smartHome,
            .remoteAccess,
            nil
        ]
        let phrases: [String] = renderOrder.compactMap { category in
            guard let count = bucketCounts[category], count > 0 else { return nil }
            return Self.phrase(forCount: count, category: category)
        }
        return Self.joinWithOxfordAnd(phrases)
    }

    // MARK: - Internals

    /// Produces the count + label phrase for a single bucket.
    /// e.g. `(3, .appleDevices)` → "3 Apple devices",
    /// `(1, nil)` → "1 other".
    private static func phrase(forCount count: Int, category: BonjourServiceCategory?) -> String {
        let labels = voiceLabels(for: category)
        let label = count == 1 ? labels.singular : labels.plural
        return "\(count) \(label)"
    }

    /// Voice-friendly labels per category. Hardcoded rather than
    /// reusing ``BonjourServiceCategory/title`` because the UI
    /// titles include words like "Devices" that don't compose
    /// cleanly into voice phrases (e.g. "3 Apple Devices devices"
    /// would be jarring). The labels here are tuned for being
    /// embedded in "<count> <label>" templates.
    private static func voiceLabels(
        for category: BonjourServiceCategory?
    ) -> (singular: String, plural: String) {
        switch category {
        case .appleDevices:
            return ("Apple device", "Apple devices")
        case .mediaAndStreaming:
            return ("media or streaming service", "media and streaming services")
        case .printersAndScanners:
            return ("printer", "printers")
        case .smartHome:
            return ("smart home device", "smart home devices")
        case .remoteAccess:
            return ("remote access service", "remote access services")
        case .none:
            return ("other", "others")
        }
    }

    /// Joins phrases with Oxford-style commas and a trailing
    /// "and" — the natural rhythm for a spoken list. One
    /// phrase passes through unchanged; two phrases use a
    /// simple " and "; three or more get the comma-and form.
    private static func joinWithOxfordAnd(_ phrases: [String]) -> String {
        switch phrases.count {
        case 0:
            return ""
        case 1:
            return phrases[0]
        case 2:
            return "\(phrases[0]) and \(phrases[1])"
        default:
            let head = phrases.dropLast().joined(separator: ", ")
            return "\(head), and \(phrases.last ?? "")"
        }
    }
}
