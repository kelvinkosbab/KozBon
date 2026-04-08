//
//  BonjourServiceType.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourLocalization

// MARK: - BonjourServiceType

/// Represents a Bonjour (mDNS/DNS-SD) service type used for network service discovery.
///
/// Each service type combines a human-readable name, a Bonjour type identifier (e.g. `"http"`),
/// and a transport layer (TCP or UDP) to form the full DNS-SD type string (e.g. `"_http._tcp"`).
/// An optional detail provides a brief description of the service.
///
/// Service types are used throughout the app for browsing, displaying, filtering, and persisting
/// discovered network services.
public struct BonjourServiceType: Hashable, Equatable, Sendable, Codable {

    /// The human-readable display name of the service type (e.g. "Web Server").
    public let name: String

    /// The Bonjour type identifier without underscores or transport suffix (e.g. `"http"`).
    public let type: String

    /// The transport layer protocol used by this service type (TCP or UDP).
    public let transportLayer: TransportLayer

    /// An optional English description of what this service type does.
    /// Use ``localizedDetail`` to get the translated version.
    public let detail: String?

    /// The complete DNS-SD type string in the format `"_type._transport"` (e.g. `"_http._tcp"`).
    public let fullType: String

    /// Returns the localized version of `detail`, looking up the English string
    /// as a key in the BonjourLocalization String Catalog. Falls back to the
    /// English `detail` if no translation is found.
    public var localizedDetail: String? {
        guard let detail else { return nil }
        return String(localized: String.LocalizationValue(detail), bundle: BonjourLocalization.bundle)
    }

    /// Creates a new Bonjour service type.
    ///
    /// The ``fullType`` property is automatically generated from `type` and `transportLayer`.
    ///
    /// - Parameters:
    ///   - name: The human-readable display name.
    ///   - type: The Bonjour type identifier (e.g. `"http"`).
    ///   - transportLayer: The transport protocol (TCP or UDP).
    ///   - detail: An optional English description of the service.
    public init(
        name: String,
        type: String,
        transportLayer: TransportLayer,
        detail: String? = nil
    ) {
        self.name = name
        self.type = type
        self.transportLayer = transportLayer
        self.detail = detail
        self.fullType = BonjourServiceType.generateFullType(
            type: type,
            transportLayer: transportLayer
        )
    }

    /// Hashes the service type using only ``fullType``, so two types with the same
    /// DNS-SD string hash identically regardless of name or detail differences.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.fullType)
    }

    /// Two service types are equal when their name, full type string, and detail all match.
    public static func == (lhs: BonjourServiceType, rhs: BonjourServiceType) -> Bool {
        return lhs.name == rhs.name && lhs.fullType == rhs.fullType && lhs.detail == rhs.detail
    }

    /// Whether this service type is part of the built-in library (as opposed to a user-created type).
    public var isBuiltIn: Bool {
        BonjourServiceType.serviceTypeLibrary.contains(self)
    }

    // MARK: - Static Helpers

    /// Generates the complete DNS-SD type string from a type identifier and transport layer.
    ///
    /// - Parameters:
    ///   - type: The Bonjour type identifier (e.g. `"http"`).
    ///   - transportLayer: The transport protocol.
    /// - Returns: The full type string in the format `"_type._transport"` (e.g. `"_http._tcp"`).
    public static func generateFullType(
        type: String,
        transportLayer: TransportLayer
    ) -> String {
        return "_\(type)._\(transportLayer.string)"
    }

    /// Returns all known service types, combining the built-in library with any user-created
    /// types persisted in Core Data.
    ///
    /// User-created types that duplicate a built-in type (same type and transport layer) are skipped.
    @MainActor
    public static func fetchAll() -> [BonjourServiceType] {
        var all = self.serviceTypeLibrary
        for persistentServiceType in self.fetchAllPersistentCopies() where
            self.fetch(serviceTypes: all, type: persistentServiceType.type, transportLayer: persistentServiceType.transportLayer) == nil {
            all.append(persistentServiceType)
        }
        return all
    }

    /// The complete built-in service type library, combining all TCP and UDP service types.
    public static var serviceTypeLibrary: [BonjourServiceType] {
        return self.tcpServiceTypes + self.udpServiceTypes
    }

    /// Finds a service type matching the given type identifier and transport layer.
    ///
    /// - Parameters:
    ///   - serviceTypes: The collection to search. Defaults to ``fetchAll()`` if `nil`.
    ///   - type: The Bonjour type identifier to match (e.g. `"http"`).
    ///   - transportLayer: The transport protocol to match.
    /// - Returns: The first matching service type, or `nil` if none is found.
    @MainActor
    public static func fetch(
        serviceTypes: [BonjourServiceType]? = nil,
        type: String,
        transportLayer: TransportLayer
    ) -> BonjourServiceType? {
        let typesToFilter = serviceTypes ?? self.fetchAll()
        let filtered = typesToFilter.filter { serviceType -> Bool in
            serviceType.type == type && serviceType.transportLayer == transportLayer
        }
        return filtered.first
    }

    /// Finds a service type matching the given full DNS-SD type string.
    ///
    /// - Parameters:
    ///   - serviceTypes: The collection to search. Defaults to ``fetchAll()`` if `nil`.
    ///   - fullType: The complete type string to match (e.g. `"_http._tcp"`).
    /// - Returns: The first matching service type, or `nil` if none is found.
    @MainActor
    public static func fetch(
        serviceTypes: [BonjourServiceType]? = nil,
        fullType: String
    ) -> BonjourServiceType? {
        let typesToFilter = serviceTypes ?? self.fetchAll()
        let filtered = typesToFilter.filter { (serviceType) -> Bool in
            serviceType.fullType == fullType
        }
        return filtered.first
    }

    /// Returns whether a service type with the given type identifier and transport layer exists.
    ///
    /// - Parameters:
    ///   - serviceTypes: The collection to search. Defaults to ``fetchAll()`` if `nil`.
    ///   - type: The Bonjour type identifier to look for.
    ///   - transportLayer: The transport protocol to match.
    /// - Returns: `true` if a matching service type is found.
    @MainActor
    public static func exists(
        serviceTypes: [BonjourServiceType]? = nil,
        type: String,
        transportLayer: TransportLayer
    ) -> Bool {
        return self.fetch(serviceTypes: serviceTypes, type: type, transportLayer: transportLayer) != nil
    }

    /// Returns whether a service type with the given full DNS-SD type string exists.
    ///
    /// - Parameters:
    ///   - serviceTypes: The collection to search. Defaults to ``fetchAll()`` if `nil`.
    ///   - fullType: The complete type string to look for (e.g. `"_http._tcp"`).
    /// - Returns: `true` if a matching service type is found.
    @MainActor
    public static func exists(
        serviceTypes: [BonjourServiceType]? = nil,
        fullType: String
    ) -> Bool {
        return self.fetch(serviceTypes: serviceTypes, fullType: fullType) != nil
    }
}
