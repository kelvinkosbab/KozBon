//
//  BonjourService+Notification.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/24/24.
//  Copyright © 2024 Kozinga. All rights reserved.
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
