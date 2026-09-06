//
//  BonjourServiceGroup.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - BonjourServiceGroup

/// Discovered services rendered as one section of the Nearby list.
///
/// Sections appear only in the states where the grouping is what the
/// user actually asked for — see
/// ``BonjourServicesViewModel/serviceGrouping``.
struct BonjourServiceGroup: Identifiable {

    /// What the section header states, so rows can leave it out
    /// instead of repeating it on every line.
    enum Key: Equatable {

        /// The header names the service type; rows carry the host.
        case serviceType

        /// The header names the host; rows carry the service type.
        case hostName
    }

    /// Which field the header spends, and therefore which one the
    /// rows beneath it must not repeat.
    let key: Key

    /// Distinct across sections in one list. Keyed on the service
    /// type's `fullType` for ``Key/serviceType`` groups rather than
    /// its display name: two types can share a name across transports
    /// (`_foo._tcp` / `_foo._udp`), and duplicate `ForEach` ids
    /// silently drop rows.
    let id: String

    /// The header text.
    let title: String

    /// Optional blurb beneath the section. Carries the service type's
    /// description for ``Key/serviceType`` groups; `nil` elsewhere,
    /// including when the library has no description for the type.
    let footerDetail: String?

    /// Members, in the order
    /// ``BonjourServicesViewModel/flatActiveServices`` produced them,
    /// so the active sort still decides how rows read inside the
    /// section.
    let services: [BonjourService]
}
