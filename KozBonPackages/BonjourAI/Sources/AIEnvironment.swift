//
//  AIEnvironment.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourModels

// MARK: - Environment Key

private struct BonjourServiceExplainerKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: (any BonjourServiceExplainerProtocol)? = nil
}

public extension EnvironmentValues {
    /// The AI service explainer, accessible via `@Environment(\.serviceExplainer)`.
    ///
    /// Returns `nil` when no explainer has been injected or when AI is unavailable.
    var serviceExplainer: (any BonjourServiceExplainerProtocol)? {
        get { self[BonjourServiceExplainerKey.self] }
        set { self[BonjourServiceExplainerKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Inject a service explainer into the view hierarchy.
    func serviceExplainer(_ explainer: any BonjourServiceExplainerProtocol) -> some View {
        self.environment(\.serviceExplainer, explainer)
    }
}
