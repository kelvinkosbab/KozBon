//
//  BonjourService+HostIdentifier.swift
//  BonjourModels
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourService + HostIdentifier

public extension BonjourService {

    /// The name identifying the device this service runs on.
    ///
    /// Shared by the Discover row title, its host section header, and
    /// the Siri summary's device count, so the three can't drift.
    ///
    /// Handles the `"NA"` sentinel that ``BonjourService/hostName``
    /// returns when the underlying `NetService.hostName` is `nil`
    /// (pre-resolution, or services that never resolve a host). A raw
    /// `"NA"` would render as an unhelpful title, so it counts as
    /// missing and the Service Name takes the slot — the same field
    /// labeled "Service Name" in the detail view.
    var hostIdentifier: String {
        let rawHostname = hostName
        let isHostnameAvailable = !rawHostname.isEmpty && rawHostname != "NA"
        return isHostnameAvailable ? rawHostname : service.name
    }
}
