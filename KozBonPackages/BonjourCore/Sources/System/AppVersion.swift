//
//  AppVersion.swift
//  BonjourCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AppVersion

/// Read access to the app's marketing version (`CFBundleShortVersionString`)
/// and build number (`CFBundleVersion`) from `Info.plist`.
///
/// Read at the call site each time rather than cached, because:
///
/// - `Bundle.main.infoDictionary` is itself effectively static for the
///   process lifetime — there's nothing to cache that the OS isn't
///   already caching.
/// - The values are only read from a couple of low-frequency UI surfaces
///   (Settings · About, debug logs, bug-report payloads), so the call
///   cost is irrelevant.
///
/// The lookup gracefully degrades: when the underlying key is missing
/// (e.g. an SPM module being used in a SwiftUI preview without an
/// embedded `Info.plist`), the accessor returns
/// ``unknownPlaceholder`` instead of crashing or returning an empty
/// string. That keeps About-section UI predictable in every host
/// context — the row reads as "missing data" instead of an unlabeled
/// blank.
public enum AppVersion {

    // MARK: - Constants

    /// Em-dash placeholder shown when version metadata can't be read.
    /// Em dash (rather than a hyphen or "Unknown") so the row visually
    /// reads as "no value here" without spawning a translation burden
    /// — the symbol is universal across every locale we ship.
    public static let unknownPlaceholder = "—"

    /// `Info.plist` key for the marketing version
    /// (`CFBundleShortVersionString`).
    private static let marketingVersionKey = "CFBundleShortVersionString"

    /// `Info.plist` key for the build number (`CFBundleVersion`).
    private static let buildNumberKey = "CFBundleVersion"

    // MARK: - Main Bundle Accessors

    /// Marketing version of the running app — what users see in the App
    /// Store and what release notes refer to (`"4.2"`). Sourced from
    /// the main bundle's `CFBundleShortVersionString`.
    public static var marketing: String {
        marketing(in: .main)
    }

    /// Build number of the running app — incremented every TestFlight /
    /// archive build (`"114"`). Sourced from the main bundle's
    /// `CFBundleVersion`. Used to disambiguate two builds that share a
    /// marketing version (e.g. multiple TestFlight builds of `"4.2"`).
    public static var build: String {
        build(in: .main)
    }

    /// Combined marketing + build form (`"4.2 (114)"`). Convenient when
    /// both pieces should be shown together in a single line — e.g. a
    /// bug-report payload or an analytics event property. UI surfaces
    /// that want the values as separate VoiceOver-labelled rows
    /// should read ``marketing`` and ``build`` directly.
    public static var formatted: String {
        "\(marketing) (\(build))"
    }

    // MARK: - Custom Bundle Accessors

    /// Marketing version read from a specific bundle. Useful for tests
    /// and for surfaces that want to inspect a non-main bundle (e.g. a
    /// hosting framework's version). Returns ``unknownPlaceholder``
    /// when the key is missing.
    public static func marketing(in bundle: Bundle) -> String {
        marketing(infoDictionary: bundle.infoDictionary)
    }

    /// Build number read from a specific bundle. See ``marketing(in:)``
    /// for the rationale.
    public static func build(in bundle: Bundle) -> String {
        build(infoDictionary: bundle.infoDictionary)
    }

    // MARK: - Info Dictionary Accessors

    /// Marketing version read from a raw `Info.plist` dictionary. The
    /// pure-data variant of ``marketing(in:)`` — exposed so tests can
    /// pass synthetic dictionaries without having to construct a
    /// real ``Bundle``. Public so downstream test targets can reuse
    /// the lookup.
    public static func marketing(infoDictionary: [String: Any]?) -> String {
        infoDictionary?[marketingVersionKey] as? String ?? unknownPlaceholder
    }

    /// Build number read from a raw `Info.plist` dictionary. See
    /// ``marketing(infoDictionary:)`` for the rationale.
    public static func build(infoDictionary: [String: Any]?) -> String {
        infoDictionary?[buildNumberKey] as? String ?? unknownPlaceholder
    }
}
