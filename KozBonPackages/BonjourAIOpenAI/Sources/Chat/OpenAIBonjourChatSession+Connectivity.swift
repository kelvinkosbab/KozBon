//
//  OpenAIBonjourChatSession+Connectivity.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import InternetConnectivity

// MARK: - OpenAIBonjourChatSession + Connectivity

extension OpenAIBonjourChatSession {

    /// Every turn calls the provider's API.
    public var connectivityRequirement: ConnectivityRequirement { .internet }
}
