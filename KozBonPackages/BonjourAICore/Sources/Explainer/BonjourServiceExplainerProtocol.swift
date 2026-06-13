//
//  BonjourServiceExplainerProtocol.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - BonjourServiceExplainerProtocol

/// Protocol for AI-powered Bonjour service explanation.
///
/// Provides an abstraction over the on-device language model so that
/// views can be tested and previewed without requiring FoundationModels.
@MainActor
public protocol BonjourServiceExplainerProtocol: AnyObject, Observable {

    /// The streamed explanation text, updated as tokens arrive.
    var explanation: String { get }

    /// Whether the model is currently generating a response.
    var isGenerating: Bool { get }

    /// An error message if generation fails.
    var error: String? { get }

    /// Whether the AI model is available on this device.
    var isAvailable: Bool { get }

    /// The desired level of technical detail in the explanation.
    var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel { get set }

    /// The desired verbosity of the explanation.
    var responseLength: BonjourServicePromptBuilder.ResponseLength { get set }

    /// Generates a streaming explanation of the given Bonjour service.
    ///
    /// - Parameters:
    ///   - service: The Bonjour service to explain.
    ///   - isPublished: Whether this service was published by this device.
    func explain(service: BonjourService, isPublished: Bool) async

    /// Generates a streaming explanation of the given Bonjour service type.
    ///
    /// - Parameter serviceType: The service type to explain (without a specific discovered instance).
    func explain(serviceType: BonjourServiceType) async

    /// Generates a streaming explanation of what a single "What's
    /// New" release highlight means for the user.
    ///
    /// Streams into the same ``explanation`` / ``isGenerating`` /
    /// ``error`` surface as the service explainers, so the Insights
    /// sheet renders it identically.
    ///
    /// - Parameters:
    ///   - releaseHighlight: The verbatim highlight bullet the user
    ///     long-pressed on the What's New page.
    ///   - version: The marketing version the highlight belongs to
    ///     (e.g. "4.6"), to ground the model's answer.
    func explain(releaseHighlight: String, version: String) async
}
