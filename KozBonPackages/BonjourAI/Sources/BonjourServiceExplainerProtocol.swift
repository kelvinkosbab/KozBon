//
//  BonjourServiceExplainerProtocol.swift
//  BonjourAI
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

    /// Generates a streaming explanation of the given Bonjour service.
    ///
    /// - Parameter service: The discovered Bonjour service to explain.
    func explain(service: BonjourService) async
}
