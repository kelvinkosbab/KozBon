//
//  AnthropicBonjourChatSession+Connectivity.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import InternetConnectivity

// MARK: - AnthropicBonjourChatSession + Connectivity

extension AnthropicBonjourChatSession {

    /// Every turn calls the provider's API.
    public var connectivityRequirement: ConnectivityRequirement { .internet }
}
