//
//  BonjourServiceGroup.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - BonjourServiceGroup

/// Discovered services that share a Bonjour service type, rendered
/// as one section of the Nearby list.
///
/// Grouping only happens in the states where a type-ordered list is
/// what the user actually asked for — see
/// ``BonjourServicesViewModel/isGroupedByServiceType``.
struct BonjourServiceGroup: Identifiable {

    /// The service type every member of ``services`` advertises.
    let serviceType: BonjourServiceType

    /// Members, in the order
    /// ``BonjourServicesViewModel/flatActiveServices`` produced
    /// them, so the active sort still decides how rows read inside
    /// the section.
    let services: [BonjourService]

    /// Keyed on `fullType` rather than the display name: two
    /// distinct types can share a name across transports
    /// (`_foo._tcp` / `_foo._udp`), and duplicate `ForEach` ids
    /// silently drop rows.
    var id: String { serviceType.fullType }

    /// Localized blurb for ``serviceType``, shown as the section
    /// footer — or `nil` when the library carries no description, so
    /// the section renders without one.
    ///
    /// Normalizes the empty string to `nil`; a type with `detail: ""`
    /// would otherwise draw an empty footer's padding.
    var footerDetail: String? {
        guard let detail = serviceType.localizedDetail, !detail.isEmpty else {
            return nil
        }
        return detail
    }
}
