//
//  GeminiBonjourChatSession+Connectivity.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import InternetConnectivity

// MARK: - GeminiBonjourChatSession + Connectivity

extension GeminiBonjourChatSession {

    /// Every turn calls the provider's API.
    public var connectivityRequirement: ConnectivityRequirement { .internet }
}
