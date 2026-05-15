//
//  AIEnvironment.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourModels

// MARK: - Environment Values

public extension EnvironmentValues {

    /// The AI service explainer, accessible via `@Environment(\.serviceExplainer)`.
    ///
    /// Returns `nil` when no explainer has been injected or when AI is unavailable.
    @Entry var serviceExplainer: (any BonjourServiceExplainerProtocol)?

    /// The Bonjour chat session, accessible via `@Environment(\.chatSession)`.
    ///
    /// Returns `nil` when no chat session has been injected or when AI is unavailable.
    @Entry var chatSession: (any BonjourChatSessionProtocol)?
}

// MARK: - View Extension

public extension View {
    /// Inject a service explainer into the view hierarchy.
    func serviceExplainer(_ explainer: any BonjourServiceExplainerProtocol) -> some View {
        self.environment(\.serviceExplainer, explainer)
    }

    /// Inject a chat session into the view hierarchy.
    func chatSession(_ session: any BonjourChatSessionProtocol) -> some View {
        self.environment(\.chatSession, session)
    }
}
