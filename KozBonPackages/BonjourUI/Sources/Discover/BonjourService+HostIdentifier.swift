//
//  BonjourService+HostIdentifier.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - BonjourService + HostIdentifier

extension BonjourService {

    /// The name identifying the device this service runs on.
    ///
    /// Shared by the row title and the host section header so the two
    /// can't drift — a header that reads differently from every row
    /// beneath it is worse than no header.
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
