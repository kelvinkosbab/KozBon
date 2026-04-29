//
//  BonjourServiceEntity.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import BonjourAI
import Foundation
import BonjourModels

// MARK: - BonjourServiceEntity

/// Shortcuts-friendly projection of a discovered ``BonjourService``.
///
/// The runtime `BonjourService` is `@MainActor`-isolated, holds a
/// non-`Sendable` `NetService`, and exposes a wide surface for
/// resolution lifecycle (``isResolving``, ``isPublishing``,
/// addresses, TXT records, etc.). None of that fits the App Intents
/// expectation: entities must be `Sendable`, value-typed, and
/// represent a stable identity the user can hold onto across
/// invocations and pipe between Shortcuts steps.
///
/// This entity captures the four fields a Shortcuts user is most
/// likely to consume — **name**, **service type**, **hostname**,
/// **port** — projected to plain `String`/`Int` so the values
/// travel through Shortcuts cleanly.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct BonjourServiceEntity: AppEntity, Sendable, Hashable {

    // MARK: - Identity

    /// Stable per-session identifier from `BonjourService.id`
    /// (derived from `NetService.hashValue`). Stable across the
    /// life of a single scan but not across launches — the
    /// `EntityQuery` below treats lookups by id as ephemeral
    /// matches against a recent snapshot.
    let id: String

    // MARK: - Display Fields

    /// User-facing service name (e.g. "Living Room TV"). What
    /// Siri reads aloud and what Shortcuts shows in the picker.
    let name: String

    /// Voice-friendly version of ``name``. For most services
    /// this is identical to `name`. For auto-generated
    /// hostname-style names with hex MAC suffixes
    /// (`iPhone-1F2A`, `unknown-AB12CD`), this carries a
    /// ``BonjourDeviceIdentifier``-derived friendly form
    /// ("iPhone", "Apple TV") so Siri reads a recognizable
    /// device class instead of pronouncing the hex character
    /// by character.
    ///
    /// Stored alongside `name` rather than replacing it because
    /// Shortcuts users may want the raw advertised name (for
    /// "copy to clipboard" / "send via SMS" steps), while the
    /// voice-rendering path wants the friendly form. Two
    /// fields, two consumers.
    let voiceFriendlyName: String

    /// Full DNS-SD service type (e.g. `_airplay._tcp`). Surface
    /// the wire form rather than a friendly name because
    /// Shortcuts users plumbing this through to a "tap to copy"
    /// or "send via Mac" step probably want the canonical
    /// identifier.
    let serviceType: String

    /// Voice- and UI-friendly display name for the service type
    /// (e.g. "AirPlay" rather than `_airplay._tcp`). Captured at
    /// init time from `BonjourServiceType.name` so the entity
    /// stays `Sendable` — without this projection, the
    /// `displayRepresentation` getter would need access to the
    /// `@MainActor`-isolated library lookup, which doesn't
    /// compose with `AppEntity`'s synchronous protocol.
    ///
    /// Falls back to the wire `serviceType` when the service's
    /// type record has no display name (custom types created
    /// without one, or rare malformed entries).
    let serviceTypeDisplayName: String

    /// Resolved hostname (`SomeMac.local.`) or the literal
    /// sentinel `"NA"` when the service hasn't resolved yet.
    /// Mirrors `BonjourService.hostName` semantics.
    let hostname: String

    /// Service port. `0` if the service hasn't resolved a port
    /// yet — the runtime model exposes `Int32`, which we widen
    /// to `Int` for Shortcuts.
    let port: Int

    // MARK: - AppEntity

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Bonjour Service",
        numericFormat: "\(placeholder: .int) Bonjour services"
    )

    /// Subtitle uses the friendly type name so Shortcuts
    /// previews show "AirPlay" rather than "_airplay._tcp" —
    /// the latter is read aloud terribly when a Shortcut step
    /// pipes the entity into "Speak Text".
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(serviceTypeDisplayName)"
        )
    }

    static let defaultQuery = BonjourServiceEntityQuery()

    // MARK: - Initialization From Runtime Model

    /// Projects a runtime ``BonjourService`` into the entity form.
    /// Captures field values now (on `@MainActor`) so the
    /// resulting entity is `Sendable` and can be returned across
    /// the App Intents boundary.
    @MainActor
    init(from service: BonjourService) {
        // `BonjourService.id` is `Int` (the cached
        // `NetService.hashValue`). App Intents `EntityIdentifier`
        // requires the id type to be `Hashable & Sendable`; any of
        // the standard scalar types qualify, but we project to
        // `String` so the id is stable across the App Intents
        // archive format and survives Shortcuts' display
        // serialization without surprises.
        self.id = String(service.id)
        self.name = service.service.name
        // Capture the voice-friendly form too. The renderer
        // returns the original verbatim for user-given names
        // ("Living Room TV") and substitutes a friendly device
        // class for hostname-style names ("iPhone-1F2A" →
        // "iPhone"), so this is safe to compute up-front for
        // every entity.
        self.voiceFriendlyName = SiriServiceNameRenderer.voiceFriendlyName(for: service)
        self.serviceType = service.serviceType.fullType
        // Capture the friendly type name now while we're on the
        // MainActor — falls back to the wire form when the type's
        // display name is empty (custom types lacking one).
        let friendlyName = service.serviceType.name
        self.serviceTypeDisplayName = friendlyName.isEmpty
            ? service.serviceType.fullType
            : friendlyName
        self.hostname = service.hostName
        self.port = service.service.port
    }
}

// MARK: - BonjourServiceEntityQuery

/// Minimal `EntityQuery` for ``BonjourServiceEntity``.
///
/// App Intents requires `defaultQuery` on every `AppEntity`, but
/// our entities are ephemeral discoveries — there's no persistent
/// store to query. The query intentionally returns empty arrays
/// for both lookup paths: callers are expected to obtain
/// entities by running ``ListDiscoveredServicesIntent`` and using
/// the returned values directly, not by re-querying by id later.
///
/// If a future iteration wants stable Shortcuts that reference a
/// specific service by name across sessions, the query body
/// can be filled in to drive a fresh scan and match by id —
/// but for Phase 2 the empty default is honest about the
/// transient nature of Bonjour state.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct BonjourServiceEntityQuery: EntityQuery {

    func entities(for identifiers: [BonjourServiceEntity.ID]) async throws -> [BonjourServiceEntity] {
        // Bonjour discoveries don't persist across sessions, so a
        // lookup by id from a Shortcut step run hours later
        // wouldn't find anything useful. Return empty rather than
        // run a fresh scan — the latter would surprise the user
        // with permission prompts in unexpected contexts.
        []
    }

    func suggestedEntities() async throws -> [BonjourServiceEntity] {
        // Same reasoning — no stable suggestions to surface.
        []
    }
}
