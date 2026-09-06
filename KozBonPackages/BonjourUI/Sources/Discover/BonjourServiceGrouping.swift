//
//  BonjourServiceGrouping.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceGrouping

/// How the Nearby list breaks discovered services into sections.
///
/// Sections follow whatever ordering the user asked for rather than
/// competing with it — see
/// ``BonjourServicesViewModel/serviceGrouping``.
enum BonjourServiceGrouping: Equatable, Sendable {

    /// One section per service type.
    case serviceType

    /// One section per device.
    case hostName

    /// A single unsectioned run.
    ///
    /// Named `flat` rather than `none` so it never reads as
    /// `Optional.none` at a call site.
    case flat
}
