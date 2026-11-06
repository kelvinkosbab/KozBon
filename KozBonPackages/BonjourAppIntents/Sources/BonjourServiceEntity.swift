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
/// The fields Shortcuts can read are declared with `@Property`, so a
/// later step can pull out the name, type, hostname, or port. Without
/// it Shortcuts sees only the title and subtitle.
public struct BonjourServiceEntity: AppEntity, Sendable, Hashable {

    // MARK: - Identity

    /// The service's DNS-SD identity, `name|type|domain`, from
    /// `BonjourService.logicalIdentity`. It survives relaunches, so a
    /// Shortcut that saved a service still finds it after a new scan.
    public let id: String

    /// Voice-friendly version of ``name``. For most services
    /// this is identical to `name`. For auto-generated
    /// hostname-style names with hex MAC suffixes
    /// (`iPhone-1F2A`, `unknown-AB12CD`), this carries a
    /// ``BonjourDeviceIdentifier``-derived friendly form
    /// ("iPhone", "Apple TV") so Siri reads a recognizable
    /// device class instead of pronouncing the hex character
    /// by character.
    ///
    /// Not a Shortcuts property: steps that copy or send the
    /// name want the advertised one.
    public let voiceFriendlyName: String

    // MARK: - Shortcuts Properties

    /// User-facing service name (e.g. "Living Room TV"). What
    /// Siri reads aloud and what Shortcuts shows in the picker.
    @Property(title: .init("intent_entity_property_name"))
    public var name: String

    /// Display name for the service type (e.g. "AirPlay"). Captured at
    /// init because the library lookup is `@MainActor` and
    /// `displayRepresentation` is synchronous. Falls back to the wire
    /// ``serviceType`` when the type has no display name.
    @Property(title: .init("intent_entity_property_type"))
    public var serviceTypeDisplayName: String

    /// Full DNS-SD service type (e.g. `_airplay._tcp`).
    @Property(title: .init("intent_entity_property_bonjour_type"))
    public var serviceType: String

    /// The resolved DNS hostname (`Living-Room.local.`), or `nil` when
    /// the service didn't resolve during the scan. Unlike
    /// `BonjourService.hostName`, this is the raw value, usable in a
    /// URL or an SSH step.
    @Property(title: .init("intent_entity_property_hostname"))
    public var hostname: String?

    /// The service port, or `nil` when it didn't resolve during the
    /// scan.
    @Property(title: .init("intent_entity_property_port"))
    public var port: Int?

    // MARK: - AppEntity

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: .init("intent_entity_type_name"),
        numericFormat: "\(placeholder: .int) Bonjour services"
    )

    /// Subtitle uses the friendly type name so Shortcuts
    /// previews show "AirPlay" rather than "_airplay._tcp" —
    /// the latter is read aloud terribly when a Shortcut step
    /// pipes the entity into "Speak Text".
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(serviceTypeDisplayName)"
        )
    }

    public static let defaultQuery = BonjourServiceEntityQuery()

    // MARK: - Initialization From Runtime Model

    /// Projects a runtime ``BonjourService`` into the entity form.
    /// Captures field values now (on `@MainActor`) so the
    /// resulting entity is `Sendable` and can be returned across
    /// the App Intents boundary.
    @MainActor
    public init(from service: BonjourService) {
        // Not `BonjourService.id`: that comes from `NetService.hashValue`
        // and changes every launch, which breaks saved Shortcuts.
        self.id = service.logicalIdentity
        // Returns user-given names ("Living Room TV") verbatim and
        // substitutes a device class for hostname-style ones
        // ("iPhone-1F2A" → "iPhone").
        self.voiceFriendlyName = SiriServiceNameRenderer.voiceFriendlyName(for: service)
        self.name = service.service.name
        let friendlyName = service.serviceType.name
        self.serviceTypeDisplayName = friendlyName.isEmpty
            ? service.serviceType.fullType
            : friendlyName
        self.serviceType = service.serviceType.fullType
        self.hostname = service.service.hostName.flatMap { $0.isEmpty ? nil : $0 }
        let port = service.service.port
        self.port = port > 0 ? port : nil
    }

    // MARK: - Hashable

    // Written by hand because the `@Property` wrappers aren't Hashable.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.serviceType == rhs.serviceType
            && lhs.hostname == rhs.hostname
            && lhs.port == rhs.port
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - BonjourServiceEntityQuery

/// Resolves ``BonjourServiceEntity`` ids against the latest List
/// result in this process.
///
/// Bonjour discoveries don't persist, so an id from an earlier launch
/// resolves to nothing. The query never starts a scan of its own: a
/// lookup can run in contexts where a local-network prompt would
/// surprise the user.
public struct BonjourServiceEntityQuery: EntityQuery {

    private let store: RecentServiceEntities

    /// Scans for services when an id isn't in the latest List result,
    /// as happens for a saved Shortcut after a relaunch. `nil` in tests.
    private let rescan: (@Sendable () async -> [BonjourServiceEntity])?

    public init() {
        self.store = .shared
        self.rescan = { await Self.scanForEntities() }
    }

    init(
        store: RecentServiceEntities,
        rescan: (@Sendable () async -> [BonjourServiceEntity])? = nil
    ) {
        self.store = store
        self.rescan = rescan
    }

    public func entities(for identifiers: [BonjourServiceEntity.ID]) async throws -> [BonjourServiceEntity] {
        let cached = await store.entities(for: identifiers)
        guard let rescan, cached.count < Set(identifiers).count else { return cached }
        await store.replace(with: await rescan())
        return await store.entities(for: identifiers)
    }

    @MainActor
    private static func scanForEntities() async -> [BonjourServiceEntity] {
        await IntentScan.run().services.map(BonjourServiceEntity.init(from:))
    }

    public func suggestedEntities() async throws -> [BonjourServiceEntity] {
        await store.all()
    }
}
