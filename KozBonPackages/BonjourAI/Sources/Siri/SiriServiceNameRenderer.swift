//
//  SiriServiceNameRenderer.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

// MARK: - SiriServiceNameRenderer

/// Voice-friendly rendering for individual `BonjourService` names.
///
/// The Bonjour service name is whatever the device chose to
/// advertise — sometimes user-given (`Living Room TV`, `Kelvin's
/// iPhone`), often auto-generated with a MAC-derived hex suffix
/// (`iPhone-1F2A`, `unknown-1A2B3C4D5E6F`). The first sounds
/// fine through TTS; the second sounds like *"i Phone dash one F
/// two A"* — robotic and unhelpful.
///
/// This renderer detects the auto-generated case and substitutes
/// a ``BonjourDeviceIdentifier``-derived friendly name when one
/// is available. User-given names are passed through unchanged
/// — substituting a name the user explicitly chose would be a
/// regression in voice quality, not an improvement.
public enum SiriServiceNameRenderer {

    // MARK: - Public

    /// Returns a name suitable for reading aloud. Substitutes a
    /// device-identifier-derived friendly form when:
    ///
    /// 1. The original name looks hostname-style (auto-generated
    ///    with a MAC-suffix-style trailing token), AND
    /// 2. ``BonjourDeviceIdentifier`` resolves the service to a
    ///    concrete device family (Apple model lookup or
    ///    hostname pattern).
    ///
    /// In all other cases — including when the original is a
    /// user-given name like "Living Room TV" — returns the
    /// original verbatim. Erring on the side of preservation
    /// keeps cases the user explicitly named from being
    /// "improved" away.
    @MainActor
    public static func voiceFriendlyName(for service: BonjourService) -> String {
        let original = service.service.name
        guard looksHostnameStyle(original) else { return original }
        guard let identification = BonjourDeviceIdentifier.identify(service: service) else {
            return original
        }
        return identification.friendlyName
    }

    /// Returns `true` if `name` matches the hostname-style
    /// auto-generated pattern: a trailing `-<hex>{4,}` segment
    /// after a base prefix. Catches `iPhone-1F2A`,
    /// `Kelvins-Mac-AB12CD`, `unknown-1A2B3C4D5E6F` etc. while
    /// leaving plain user names like "Living Room TV",
    /// "Kelvin's iPhone", "Kelvins-MacBook-Pro" untouched.
    ///
    /// Hex-only is the discriminating signal — all-uppercase
    /// alphanumeric wouldn't be specific enough (would match
    /// arbitrary words in capitals). Mac-address-derived
    /// suffixes are universally hex.
    public static func looksHostnameStyle(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        // The pattern requires a hex-character suffix of 4+
        // characters following a hyphen, anchored to end of
        // string. Length 4+ rules out short hex words like
        // "fade" appearing organically in regular names.
        let pattern = "-[A-Fa-f0-9]{4,}$"
        return name.range(of: pattern, options: .regularExpression) != nil
    }
}
