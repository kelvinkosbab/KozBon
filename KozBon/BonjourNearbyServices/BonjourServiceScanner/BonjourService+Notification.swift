//
//  BonjourService+Notification.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourService + Notification

extension Notification.Name {
    static let netServiceResolveAddressComplete = Notification.Name(rawValue: "BonjourService).netServiceResolveAddressComplete")
    static let netServiceDidPublish = Notification.Name(rawValue: "BonjourServicenetServiceDidPublish")
    static let netServiceDidUnPublish = Notification.Name(rawValue: "BonjourServicenetServiceDidUnPublish")
    static let netServiceDidNotPublish = Notification.Name(rawValue: "BonjourServicenetServiceDidNotPublish")
    static let netServiceDidStop = Notification.Name(rawValue: "BonjourServicenetServiceDidStop")
}
