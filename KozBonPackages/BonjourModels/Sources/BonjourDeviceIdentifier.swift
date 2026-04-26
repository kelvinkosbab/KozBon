//
//  BonjourDeviceIdentifier.swift
//  BonjourModels
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore

// MARK: - DeviceIdentification

/// The result of identifying the device behind a discovered Bonjour
/// service. Returned by ``BonjourDeviceIdentifier/identify(service:)``.
public struct DeviceIdentification: Sendable, Equatable {

    /// Human-readable name of the identified device, e.g.
    /// "iPhone 15 Pro Max", "Apple TV 4K (3rd generation)", "iPhone".
    public let friendlyName: String

    /// Coarse-grained category. Drives the sidebar icon in the detail
    /// view and may eventually drive a category filter on the
    /// Discover tab.
    public let category: Category

    /// How confident we are in the identification. `.high` is "we
    /// looked up an exact model identifier"; `.medium` is "we matched
    /// the device family from the hostname or generic TXT record but
    /// don't know the specific model"; `.low` is reserved for future
    /// fuzzy strategies.
    public let confidence: Confidence

    public init(friendlyName: String, category: Category, confidence: Confidence) {
        self.friendlyName = friendlyName
        self.category = category
        self.confidence = confidence
    }

    // MARK: - Category

    /// Coarse device category. Apple-focused for now — non-Apple
    /// devices fall through to ``BonjourDeviceIdentifier``'s
    /// no-match path. Add new cases here as device-class coverage
    /// expands.
    public enum Category: String, Sendable, CaseIterable, Codable {
        case phone
        case tablet
        case computer
        case tv
        case speaker
        case watch
        case accessory

        /// SF Symbol name suitable for showing next to the device
        /// row in the service detail view.
        public var iconName: String {
            switch self {
            case .phone: "iphone"
            case .tablet: "ipad"
            case .computer: "laptopcomputer"
            case .tv: "appletv"
            case .speaker: "homepod"
            case .watch: "applewatch"
            case .accessory: "shippingbox"
            }
        }
    }

    // MARK: - Confidence

    public enum Confidence: Sendable, Codable {
        /// Exact model identifier resolved through Apple's wire-format
        /// table (e.g., `iPhone16,1` → "iPhone 15 Pro").
        case high

        /// Device family matched but the exact model is unknown
        /// (e.g., hostname `Kelvins-iPhone.local.` resolves to "iPhone"
        /// with no generation).
        case medium

        /// Reserved for future fuzzy strategies. Not currently
        /// produced by any active path.
        case low
    }
}

// MARK: - BonjourDeviceIdentifier

/// Pure-deterministic identifier for the device behind a discovered
/// Bonjour service. Apple-only in this iteration — other vendors fall
/// through to a `nil` result and remain available via the AI Insights
/// long-press menu.
///
/// Strategies are tried in priority order; the first match wins:
///
/// 1. **Apple model identifier in a TXT record** (`high` confidence).
///    Looks up keys `model`, `mdl`, and `md` against
///    ``BonjourDeviceIdentifier/appleModelLookup`` — Apple's wire-
///    format identifier table. Produces e.g. "iPhone 15 Pro Max" from
///    `model=iPhone16,2`.
///
/// 2. **Hostname / service name pattern** (`medium` confidence).
///    Matches Apple device-family keywords ("iphone", "ipad",
///    "macbook", "apple tv", etc.) in the service's hostname or
///    advertised name. Produces a family name without a model
///    generation, e.g. "iPhone" or "Apple TV".
///
/// Future work (not in this commit): vendor-specific TXT extraction
/// for Sonos / Hue / LIFX / Ecobee / Roku, generic
/// `manufacturer=`/`model=` extraction for long-tail IoT, and
/// service-type-based category fallbacks.
public enum BonjourDeviceIdentifier {

    // MARK: - Public API

    /// Identifies the device behind a discovered Bonjour service.
    /// Returns `nil` if no strategy matched — callers can render
    /// the detail view without a Device row in that case.
    @MainActor
    public static func identify(service: BonjourService) -> DeviceIdentification? {
        identify(
            txtRecords: service.dataRecords,
            hostname: service.hostName,
            serviceName: service.service.name
        )
    }

    /// Primitive-parameter identification entry point. Useful for
    /// unit tests (no MainActor / `BonjourService` construction
    /// required) and as the actual workhorse the convenience
    /// overload above delegates to.
    public static func identify(
        txtRecords: [BonjourService.TxtDataRecord],
        hostname: String,
        serviceName: String
    ) -> DeviceIdentification? {
        if let identification = identifyFromAppleModelTxt(txtRecords: txtRecords) {
            return identification
        }
        if let identification = identifyFromHostnamePattern(hostname: hostname, serviceName: serviceName) {
            return identification
        }
        return nil
    }

    // MARK: - Strategy: TXT Record Apple Model Lookup

    /// Inspects each TXT record looking for an Apple-style hardware
    /// identifier (`iPhone16,1`, `AppleTV14,1`, `Mac15,12`, etc.) in
    /// any of the model-bearing keys. Returns the first hit
    /// translated through the model table.
    static func identifyFromAppleModelTxt(
        txtRecords: [BonjourService.TxtDataRecord]
    ) -> DeviceIdentification? {
        // Priority order: `model` is the canonical key (`_device-info._tcp`,
        // AirPlay), `mdl` is used by some services like
        // `_companion-link._tcp` and Sonos, `md` is HomeKit's model
        // description (which is sometimes a wire identifier and
        // sometimes a vendor name).
        let modelKeys: Set<String> = ["model", "mdl", "md"]

        for record in txtRecords {
            guard modelKeys.contains(record.key.lowercased()) else { continue }
            if let entry = appleModelLookup[record.value] {
                return DeviceIdentification(
                    friendlyName: entry.friendlyName,
                    category: entry.category,
                    confidence: .high
                )
            }
        }
        return nil
    }

    // MARK: - Strategy: Hostname Pattern

    /// Falls back to keyword matching on the supplied hostname and
    /// advertised service name. The user's device name often
    /// telegraphs the device family even when the service itself
    /// doesn't expose a model identifier — e.g.,
    /// `Kelvins-iPhone.local.` or `Living-Room-Apple-TV.local.`.
    static func identifyFromHostnamePattern(
        hostname: String,
        serviceName: String
    ) -> DeviceIdentification? {
        // Build a single lowercase needle from both the hostname and
        // the user-facing service name. The advertised service name
        // (e.g., "Kelvin's iPhone") is sometimes friendlier than the
        // sanitized DNS hostname.
        let needle = "\(hostname.lowercased()) \(serviceName.lowercased())"

        // Order matters: more specific patterns first so generic
        // substrings ("mac", "apple") don't pre-empt them.
        for pattern in hostnamePatterns where pattern.matches(needle) {
            return DeviceIdentification(
                friendlyName: pattern.friendlyName,
                category: pattern.category,
                confidence: .medium
            )
        }
        return nil
    }

    // MARK: - Hostname Patterns

    /// Apple device-family keyword patterns checked in priority order.
    /// Each pattern carries the hostname needle (lowercase substring),
    /// the friendly name to show, and the device category.
    static let hostnamePatterns: [HostnamePattern] = [
        // Compound names first so "macbook" doesn't match before
        // "macbook pro" gets a chance. We trim spaces in `matches`
        // so "macbookpro" and "macbook pro" both hit.
        .init(needle: "macbook pro", friendlyName: "MacBook Pro", category: .computer),
        .init(needle: "macbook air", friendlyName: "MacBook Air", category: .computer),
        .init(needle: "macbookpro", friendlyName: "MacBook Pro", category: .computer),
        .init(needle: "macbookair", friendlyName: "MacBook Air", category: .computer),
        .init(needle: "macbook", friendlyName: "MacBook", category: .computer),
        .init(needle: "mac mini", friendlyName: "Mac mini", category: .computer),
        .init(needle: "macmini", friendlyName: "Mac mini", category: .computer),
        .init(needle: "mac studio", friendlyName: "Mac Studio", category: .computer),
        .init(needle: "macstudio", friendlyName: "Mac Studio", category: .computer),
        .init(needle: "mac pro", friendlyName: "Mac Pro", category: .computer),
        .init(needle: "macpro", friendlyName: "Mac Pro", category: .computer),
        .init(needle: "imac", friendlyName: "iMac", category: .computer),

        .init(needle: "iphone", friendlyName: "iPhone", category: .phone),
        .init(needle: "ipad", friendlyName: "iPad", category: .tablet),
        .init(needle: "ipod", friendlyName: "iPod touch", category: .phone),

        .init(needle: "apple tv", friendlyName: "Apple TV", category: .tv),
        .init(needle: "appletv", friendlyName: "Apple TV", category: .tv),
        .init(needle: "apple-tv", friendlyName: "Apple TV", category: .tv),

        .init(needle: "homepod mini", friendlyName: "HomePod mini", category: .speaker),
        .init(needle: "homepodmini", friendlyName: "HomePod mini", category: .speaker),
        .init(needle: "homepod", friendlyName: "HomePod", category: .speaker),

        .init(needle: "apple watch", friendlyName: "Apple Watch", category: .watch),
        .init(needle: "applewatch", friendlyName: "Apple Watch", category: .watch),
        .init(needle: "apple-watch", friendlyName: "Apple Watch", category: .watch),

        .init(needle: "airpods", friendlyName: "AirPods", category: .accessory),
        .init(needle: "airport", friendlyName: "AirPort Base Station", category: .accessory)
    ]

    /// Hostname-keyword pattern. Match is case-insensitive (the
    /// needle is already lowercase) and substring-based — so
    /// `"living-room-apple-tv-4k"` matches the `"apple tv"` pattern
    /// once the hyphens are normalized.
    public struct HostnamePattern: Sendable, Equatable {
        public let needle: String
        public let friendlyName: String
        public let category: DeviceIdentification.Category

        public init(
            needle: String,
            friendlyName: String,
            category: DeviceIdentification.Category
        ) {
            self.needle = needle
            self.friendlyName = friendlyName
            self.category = category
        }

        /// Returns true if the supplied lowercase haystack contains
        /// the pattern, ignoring hyphens and underscores so common
        /// hostname conventions (`apple-tv`, `living_room_homepod`)
        /// hit the pattern just like spaces would.
        public func matches(_ haystack: String) -> Bool {
            let normalizedHaystack = haystack
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
            let normalizedNeedle = needle
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
            return normalizedHaystack.contains(normalizedNeedle)
        }
    }

    // MARK: - Apple Model Lookup Table

    /// Apple wire-format model identifiers mapped to friendly names
    /// and categories. The table is curated by hand against
    /// the iPhone Wiki and Apple's hardware launch announcements;
    /// new entries should be added when Apple ships new hardware.
    ///
    /// Coverage focus: hardware released since the iPhone 8 (2017)
    /// and Apple Silicon Macs — that's the population a typical
    /// modern user is likely to have on their network. Earlier
    /// devices fall through to the hostname-pattern strategy and
    /// still produce a family-level identification (e.g., "iPhone").
    static let appleModelLookup: [String: ModelEntry] = [
        // MARK: iPhone (8 onwards)
        "iPhone10,1": .init(friendlyName: "iPhone 8", category: .phone),
        "iPhone10,4": .init(friendlyName: "iPhone 8", category: .phone),
        "iPhone10,2": .init(friendlyName: "iPhone 8 Plus", category: .phone),
        "iPhone10,5": .init(friendlyName: "iPhone 8 Plus", category: .phone),
        "iPhone10,3": .init(friendlyName: "iPhone X", category: .phone),
        "iPhone10,6": .init(friendlyName: "iPhone X", category: .phone),
        "iPhone11,2": .init(friendlyName: "iPhone XS", category: .phone),
        "iPhone11,4": .init(friendlyName: "iPhone XS Max", category: .phone),
        "iPhone11,6": .init(friendlyName: "iPhone XS Max", category: .phone),
        "iPhone11,8": .init(friendlyName: "iPhone XR", category: .phone),
        "iPhone12,1": .init(friendlyName: "iPhone 11", category: .phone),
        "iPhone12,3": .init(friendlyName: "iPhone 11 Pro", category: .phone),
        "iPhone12,5": .init(friendlyName: "iPhone 11 Pro Max", category: .phone),
        "iPhone12,8": .init(friendlyName: "iPhone SE (2nd generation)", category: .phone),
        "iPhone13,1": .init(friendlyName: "iPhone 12 mini", category: .phone),
        "iPhone13,2": .init(friendlyName: "iPhone 12", category: .phone),
        "iPhone13,3": .init(friendlyName: "iPhone 12 Pro", category: .phone),
        "iPhone13,4": .init(friendlyName: "iPhone 12 Pro Max", category: .phone),
        "iPhone14,2": .init(friendlyName: "iPhone 13 Pro", category: .phone),
        "iPhone14,3": .init(friendlyName: "iPhone 13 Pro Max", category: .phone),
        "iPhone14,4": .init(friendlyName: "iPhone 13 mini", category: .phone),
        "iPhone14,5": .init(friendlyName: "iPhone 13", category: .phone),
        "iPhone14,6": .init(friendlyName: "iPhone SE (3rd generation)", category: .phone),
        "iPhone14,7": .init(friendlyName: "iPhone 14", category: .phone),
        "iPhone14,8": .init(friendlyName: "iPhone 14 Plus", category: .phone),
        "iPhone15,2": .init(friendlyName: "iPhone 14 Pro", category: .phone),
        "iPhone15,3": .init(friendlyName: "iPhone 14 Pro Max", category: .phone),
        "iPhone15,4": .init(friendlyName: "iPhone 15", category: .phone),
        "iPhone15,5": .init(friendlyName: "iPhone 15 Plus", category: .phone),
        "iPhone16,1": .init(friendlyName: "iPhone 15 Pro", category: .phone),
        "iPhone16,2": .init(friendlyName: "iPhone 15 Pro Max", category: .phone),
        "iPhone17,1": .init(friendlyName: "iPhone 16 Pro", category: .phone),
        "iPhone17,2": .init(friendlyName: "iPhone 16 Pro Max", category: .phone),
        "iPhone17,3": .init(friendlyName: "iPhone 16", category: .phone),
        "iPhone17,4": .init(friendlyName: "iPhone 16 Plus", category: .phone),

        // MARK: iPad (5th generation onwards)
        "iPad7,5": .init(friendlyName: "iPad (6th generation)", category: .tablet),
        "iPad7,6": .init(friendlyName: "iPad (6th generation)", category: .tablet),
        "iPad7,11": .init(friendlyName: "iPad (7th generation)", category: .tablet),
        "iPad7,12": .init(friendlyName: "iPad (7th generation)", category: .tablet),
        "iPad11,1": .init(friendlyName: "iPad mini (5th generation)", category: .tablet),
        "iPad11,2": .init(friendlyName: "iPad mini (5th generation)", category: .tablet),
        "iPad11,3": .init(friendlyName: "iPad Air (3rd generation)", category: .tablet),
        "iPad11,4": .init(friendlyName: "iPad Air (3rd generation)", category: .tablet),
        "iPad11,6": .init(friendlyName: "iPad (8th generation)", category: .tablet),
        "iPad11,7": .init(friendlyName: "iPad (8th generation)", category: .tablet),
        "iPad12,1": .init(friendlyName: "iPad (9th generation)", category: .tablet),
        "iPad12,2": .init(friendlyName: "iPad (9th generation)", category: .tablet),
        "iPad13,1": .init(friendlyName: "iPad Air (4th generation)", category: .tablet),
        "iPad13,2": .init(friendlyName: "iPad Air (4th generation)", category: .tablet),
        "iPad13,4": .init(friendlyName: "iPad Pro 11-inch (3rd generation)", category: .tablet),
        "iPad13,5": .init(friendlyName: "iPad Pro 11-inch (3rd generation)", category: .tablet),
        "iPad13,6": .init(friendlyName: "iPad Pro 11-inch (3rd generation)", category: .tablet),
        "iPad13,7": .init(friendlyName: "iPad Pro 11-inch (3rd generation)", category: .tablet),
        "iPad13,8": .init(friendlyName: "iPad Pro 12.9-inch (5th generation)", category: .tablet),
        "iPad13,9": .init(friendlyName: "iPad Pro 12.9-inch (5th generation)", category: .tablet),
        "iPad13,10": .init(friendlyName: "iPad Pro 12.9-inch (5th generation)", category: .tablet),
        "iPad13,11": .init(friendlyName: "iPad Pro 12.9-inch (5th generation)", category: .tablet),
        "iPad13,16": .init(friendlyName: "iPad Air (5th generation)", category: .tablet),
        "iPad13,17": .init(friendlyName: "iPad Air (5th generation)", category: .tablet),
        "iPad13,18": .init(friendlyName: "iPad (10th generation)", category: .tablet),
        "iPad13,19": .init(friendlyName: "iPad (10th generation)", category: .tablet),
        "iPad14,1": .init(friendlyName: "iPad mini (6th generation)", category: .tablet),
        "iPad14,2": .init(friendlyName: "iPad mini (6th generation)", category: .tablet),
        "iPad14,3": .init(friendlyName: "iPad Pro 11-inch (4th generation)", category: .tablet),
        "iPad14,4": .init(friendlyName: "iPad Pro 11-inch (4th generation)", category: .tablet),
        "iPad14,5": .init(friendlyName: "iPad Pro 12.9-inch (6th generation)", category: .tablet),
        "iPad14,6": .init(friendlyName: "iPad Pro 12.9-inch (6th generation)", category: .tablet),
        "iPad14,8": .init(friendlyName: "iPad Air 11-inch (M2)", category: .tablet),
        "iPad14,9": .init(friendlyName: "iPad Air 11-inch (M2)", category: .tablet),
        "iPad14,10": .init(friendlyName: "iPad Air 13-inch (M2)", category: .tablet),
        "iPad14,11": .init(friendlyName: "iPad Air 13-inch (M2)", category: .tablet),
        "iPad16,1": .init(friendlyName: "iPad mini (7th generation)", category: .tablet),
        "iPad16,2": .init(friendlyName: "iPad mini (7th generation)", category: .tablet),
        "iPad16,3": .init(friendlyName: "iPad Pro 11-inch (M4)", category: .tablet),
        "iPad16,4": .init(friendlyName: "iPad Pro 11-inch (M4)", category: .tablet),
        "iPad16,5": .init(friendlyName: "iPad Pro 13-inch (M4)", category: .tablet),
        "iPad16,6": .init(friendlyName: "iPad Pro 13-inch (M4)", category: .tablet),

        // MARK: Apple Silicon Macs
        // MacBook Pro
        "MacBookPro17,1": .init(friendlyName: "MacBook Pro 13\" (M1)", category: .computer),
        "MacBookPro18,1": .init(friendlyName: "MacBook Pro 16\" (M1 Pro)", category: .computer),
        "MacBookPro18,2": .init(friendlyName: "MacBook Pro 16\" (M1 Max)", category: .computer),
        "MacBookPro18,3": .init(friendlyName: "MacBook Pro 14\" (M1 Pro)", category: .computer),
        "MacBookPro18,4": .init(friendlyName: "MacBook Pro 14\" (M1 Max)", category: .computer),
        "Mac14,5": .init(friendlyName: "MacBook Pro 14\" (M2 Max)", category: .computer),
        "Mac14,6": .init(friendlyName: "MacBook Pro 16\" (M2 Max)", category: .computer),
        "Mac14,7": .init(friendlyName: "MacBook Pro 13\" (M2)", category: .computer),
        "Mac14,9": .init(friendlyName: "MacBook Pro 14\" (M2 Pro)", category: .computer),
        "Mac14,10": .init(friendlyName: "MacBook Pro 16\" (M2 Pro)", category: .computer),
        "Mac15,3": .init(friendlyName: "MacBook Pro 14\" (M3)", category: .computer),
        "Mac15,6": .init(friendlyName: "MacBook Pro 14\" (M3 Pro)", category: .computer),
        "Mac15,7": .init(friendlyName: "MacBook Pro 16\" (M3 Pro)", category: .computer),
        "Mac15,8": .init(friendlyName: "MacBook Pro 14\" (M3 Max)", category: .computer),
        "Mac15,9": .init(friendlyName: "MacBook Pro 16\" (M3 Max)", category: .computer),
        "Mac15,10": .init(friendlyName: "MacBook Pro 14\" (M3 Max)", category: .computer),
        "Mac15,11": .init(friendlyName: "MacBook Pro 16\" (M3 Max)", category: .computer),
        "Mac16,1": .init(friendlyName: "MacBook Pro 14\" (M4)", category: .computer),
        "Mac16,5": .init(friendlyName: "MacBook Pro 16\" (M4 Pro)", category: .computer),
        "Mac16,6": .init(friendlyName: "MacBook Pro 14\" (M4 Pro)", category: .computer),
        "Mac16,7": .init(friendlyName: "MacBook Pro 16\" (M4 Max)", category: .computer),
        "Mac16,8": .init(friendlyName: "MacBook Pro 14\" (M4 Max)", category: .computer),

        // MacBook Air
        "MacBookAir10,1": .init(friendlyName: "MacBook Air (M1)", category: .computer),
        "Mac14,2": .init(friendlyName: "MacBook Air 13\" (M2)", category: .computer),
        "Mac14,15": .init(friendlyName: "MacBook Air 15\" (M2)", category: .computer),
        "Mac15,12": .init(friendlyName: "MacBook Air 13\" (M3)", category: .computer),
        "Mac15,13": .init(friendlyName: "MacBook Air 15\" (M3)", category: .computer),
        "Mac16,12": .init(friendlyName: "MacBook Air 13\" (M4)", category: .computer),
        "Mac16,13": .init(friendlyName: "MacBook Air 15\" (M4)", category: .computer),

        // Mac mini / Mac Studio / Mac Pro / iMac
        "Macmini9,1": .init(friendlyName: "Mac mini (M1)", category: .computer),
        "Mac14,3": .init(friendlyName: "Mac mini (M2)", category: .computer),
        "Mac14,12": .init(friendlyName: "Mac mini (M2 Pro)", category: .computer),
        "Mac16,10": .init(friendlyName: "Mac mini (M4)", category: .computer),
        "Mac16,11": .init(friendlyName: "Mac mini (M4 Pro)", category: .computer),
        "Mac13,1": .init(friendlyName: "Mac Studio (M1 Max)", category: .computer),
        "Mac13,2": .init(friendlyName: "Mac Studio (M1 Ultra)", category: .computer),
        "Mac14,13": .init(friendlyName: "Mac Studio (M2 Max)", category: .computer),
        "Mac14,14": .init(friendlyName: "Mac Studio (M2 Ultra)", category: .computer),
        "Mac15,14": .init(friendlyName: "Mac Studio (M4 Max)", category: .computer),
        "Mac14,8": .init(friendlyName: "Mac Pro (M2 Ultra)", category: .computer),
        "iMac21,1": .init(friendlyName: "iMac (M1)", category: .computer),
        "iMac21,2": .init(friendlyName: "iMac (M1)", category: .computer),
        "Mac15,4": .init(friendlyName: "iMac (M3)", category: .computer),
        "Mac15,5": .init(friendlyName: "iMac (M3)", category: .computer),
        "Mac16,3": .init(friendlyName: "iMac (M4)", category: .computer),

        // MARK: Apple TV
        "AppleTV5,3": .init(friendlyName: "Apple TV HD (4th generation)", category: .tv),
        "AppleTV6,2": .init(friendlyName: "Apple TV 4K (1st generation)", category: .tv),
        "AppleTV11,1": .init(friendlyName: "Apple TV 4K (2nd generation)", category: .tv),
        "AppleTV14,1": .init(friendlyName: "Apple TV 4K (3rd generation)", category: .tv),

        // MARK: HomePod
        "AudioAccessory1,1": .init(friendlyName: "HomePod (1st generation)", category: .speaker),
        "AudioAccessory1,2": .init(friendlyName: "HomePod (1st generation)", category: .speaker),
        "AudioAccessory5,1": .init(friendlyName: "HomePod mini", category: .speaker),
        "AudioAccessory6,1": .init(friendlyName: "HomePod (2nd generation)", category: .speaker),

        // MARK: Apple Watch (recent — older Series 1-4 omitted; they
        //       rarely advertise discoverable Bonjour services anyway).
        "Watch5,1": .init(friendlyName: "Apple Watch Series 5", category: .watch),
        "Watch5,2": .init(friendlyName: "Apple Watch Series 5", category: .watch),
        "Watch5,3": .init(friendlyName: "Apple Watch Series 5", category: .watch),
        "Watch5,4": .init(friendlyName: "Apple Watch Series 5", category: .watch),
        "Watch5,9": .init(friendlyName: "Apple Watch SE (1st generation)", category: .watch),
        "Watch5,10": .init(friendlyName: "Apple Watch SE (1st generation)", category: .watch),
        "Watch5,11": .init(friendlyName: "Apple Watch SE (1st generation)", category: .watch),
        "Watch5,12": .init(friendlyName: "Apple Watch SE (1st generation)", category: .watch),
        "Watch6,1": .init(friendlyName: "Apple Watch Series 6", category: .watch),
        "Watch6,2": .init(friendlyName: "Apple Watch Series 6", category: .watch),
        "Watch6,3": .init(friendlyName: "Apple Watch Series 6", category: .watch),
        "Watch6,4": .init(friendlyName: "Apple Watch Series 6", category: .watch),
        "Watch6,6": .init(friendlyName: "Apple Watch Series 7", category: .watch),
        "Watch6,7": .init(friendlyName: "Apple Watch Series 7", category: .watch),
        "Watch6,8": .init(friendlyName: "Apple Watch Series 7", category: .watch),
        "Watch6,9": .init(friendlyName: "Apple Watch Series 7", category: .watch),
        "Watch6,10": .init(friendlyName: "Apple Watch SE (2nd generation)", category: .watch),
        "Watch6,11": .init(friendlyName: "Apple Watch SE (2nd generation)", category: .watch),
        "Watch6,12": .init(friendlyName: "Apple Watch SE (2nd generation)", category: .watch),
        "Watch6,13": .init(friendlyName: "Apple Watch SE (2nd generation)", category: .watch),
        "Watch6,14": .init(friendlyName: "Apple Watch Series 8", category: .watch),
        "Watch6,15": .init(friendlyName: "Apple Watch Series 8", category: .watch),
        "Watch6,16": .init(friendlyName: "Apple Watch Series 8", category: .watch),
        "Watch6,17": .init(friendlyName: "Apple Watch Series 8", category: .watch),
        "Watch6,18": .init(friendlyName: "Apple Watch Ultra", category: .watch),
        "Watch7,1": .init(friendlyName: "Apple Watch Series 9", category: .watch),
        "Watch7,2": .init(friendlyName: "Apple Watch Series 9", category: .watch),
        "Watch7,3": .init(friendlyName: "Apple Watch Series 9", category: .watch),
        "Watch7,4": .init(friendlyName: "Apple Watch Series 9", category: .watch),
        "Watch7,5": .init(friendlyName: "Apple Watch Ultra 2", category: .watch),
        "Watch7,8": .init(friendlyName: "Apple Watch Series 10", category: .watch),
        "Watch7,9": .init(friendlyName: "Apple Watch Series 10", category: .watch),
        "Watch7,10": .init(friendlyName: "Apple Watch Series 10", category: .watch),
        "Watch7,11": .init(friendlyName: "Apple Watch Series 10", category: .watch)
    ]

    /// Internal entry stored in ``appleModelLookup`` — the friendly
    /// name and category for one Apple wire-format identifier.
    struct ModelEntry: Sendable, Equatable {
        let friendlyName: String
        let category: DeviceIdentification.Category
    }
}
