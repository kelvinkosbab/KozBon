//
//  MockBonjourServiceExplainer.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - MockBonjourServiceExplainer

/// A mock implementation of ``BonjourServiceExplainerProtocol`` for testing and previews.
///
/// Returns a canned explanation immediately without requiring FoundationModels.
@MainActor
@Observable
public final class MockBonjourServiceExplainer: BonjourServiceExplainerProtocol {

    // MARK: - Properties

    public var explanation: String = ""
    public var isGenerating: Bool = false
    public var error: String?
    public var isAvailable: Bool
    public var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic

    /// The number of times ``explain(service:)`` has been called.
    public var explainCallCount = 0

    /// The canned response returned by ``explain(service:)``.
    public var cannedExplanation: String

    // MARK: - Init

    /// Creates a mock explainer.
    ///
    /// - Parameters:
    ///   - isAvailable: Whether the mock reports AI as available. Defaults to `true`.
    ///   - cannedExplanation: The explanation text to return. Defaults to a sample response.
    public init(
        isAvailable: Bool = true,
        cannedExplanation: String = "This is a mock AI explanation for testing purposes."
    ) {
        self.isAvailable = isAvailable
        self.cannedExplanation = cannedExplanation
    }

    // MARK: - BonjourServiceExplainerProtocol

    public func explain(service: BonjourService, isPublished: Bool = false) async {
        explainCallCount += 1
        explanation = ""
        error = nil
        isGenerating = true
        explanation = cannedExplanation
        isGenerating = false
    }

    public func explain(serviceType: BonjourServiceType) async {
        explainCallCount += 1
        explanation = ""
        error = nil
        isGenerating = true
        explanation = cannedExplanation
        isGenerating = false
    }
}
