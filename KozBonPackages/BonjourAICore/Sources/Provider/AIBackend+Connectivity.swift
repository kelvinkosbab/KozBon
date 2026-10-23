//
//  AIBackend+Connectivity.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import InternetConnectivity

// MARK: - AIBackend + Connectivity

public extension AIBackend {

    /// Cloud backends call a remote API; Apple Intelligence runs on
    /// the device and keeps working offline.
    var connectivityRequirement: ConnectivityRequirement {
        isCloud ? .internet : .none
    }
}
