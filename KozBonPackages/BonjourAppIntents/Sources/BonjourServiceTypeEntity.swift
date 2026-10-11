//
//  BonjourServiceTypeEntity.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourModels

// MARK: - BonjourServiceTypeEntity

/// A service type from the library, such as AirPlay or SSH, for the
/// actions that take one: Find, Explain, and Broadcast.
public struct BonjourServiceTypeEntity: AppEntity, Sendable, Hashable {

    /// The full DNS-SD type (`_airplay._tcp`). Stable across launches,
    /// unlike a discovered service's id.
    public let id: String

    /// The library name ("AirPlay").
    public let name: String

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: .init("intent_type_entity_type_name"),
        numericFormat: "\(placeholder: .int) service types"
    )

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(id)")
    }

    public static let defaultQuery = BonjourServiceTypeEntityQuery()

    public init(serviceType: BonjourServiceType) {
        self.id = serviceType.fullType
        self.name = serviceType.name
    }
}

// MARK: - BonjourServiceTypeEntityQuery

/// Resolves service types against the library plus the user's custom
/// types, so Siri can match "AirPlay" when it asks which type.
public struct BonjourServiceTypeEntityQuery: EntityStringQuery {

    public init() {}

    public func entities(for identifiers: [BonjourServiceTypeEntity.ID]) async throws -> [BonjourServiceTypeEntity] {
        let wanted = Set(identifiers)
        return await MainActor.run {
            BonjourServiceType.fetchAll()
                .filter { wanted.contains($0.fullType) }
                .map(BonjourServiceTypeEntity.init(serviceType:))
        }
    }

    public func entities(matching string: String) async throws -> [BonjourServiceTypeEntity] {
        await MainActor.run {
            Self.matching(string, in: BonjourServiceType.fetchAll())
                .map(BonjourServiceTypeEntity.init(serviceType:))
        }
    }

    public func suggestedEntities() async throws -> [BonjourServiceTypeEntity] {
        await MainActor.run {
            BonjourServiceType.fetchAll()
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                .map(BonjourServiceTypeEntity.init(serviceType:))
        }
    }

    /// Types whose name or wire type contains `query`, ignoring case
    /// and accents. Exact name matches come first, then names that
    /// start with the query, then the rest by name.
    static func matching(_ query: String, in types: [BonjourServiceType]) -> [BonjourServiceType] {
        let needle = normalized(query)
        guard !needle.isEmpty else { return [] }

        func rank(_ type: BonjourServiceType) -> Int? {
            let name = normalized(type.name)
            if name == needle || normalized(type.type) == needle { return 0 }
            if name.hasPrefix(needle) { return 1 }
            if name.contains(needle) || normalized(type.fullType).contains(needle) { return 2 }
            return nil
        }

        return types
            .compactMap { type in rank(type).map { (type, $0) } }
            .sorted { lhs, rhs in
                lhs.1 != rhs.1
                    ? lhs.1 < rhs.1
                    : lhs.0.name.localizedStandardCompare(rhs.0.name) == .orderedAscending
            }
            .map(\.0)
    }

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
