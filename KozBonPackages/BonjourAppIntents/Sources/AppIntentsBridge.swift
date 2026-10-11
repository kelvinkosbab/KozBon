//
//  AppIntentsBridge.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Observation
import BonjourAI
import BonjourModels
import BonjourScanning

// MARK: - OpenServiceRequest

/// A service the Open in KozBon action asked the app to show.
public struct OpenServiceRequest: Equatable, Sendable {

    /// The advertised service name.
    public let name: String

    /// The full DNS-SD type (`_airplay._tcp`).
    public let serviceType: String

    public init(name: String, serviceType: String) {
        self.name = name
        self.serviceType = serviceType
    }
}

// MARK: - AppIntentsBridge

/// What the app hands the Siri actions that act on its own state:
/// broadcasting, explaining, and opening a service.
///
/// The app fills this in at launch, before any scene exists, because
/// the system can launch KozBon in the background just to run an
/// action. Actions that only scan don't need it.
@MainActor
@Observable
public final class AppIntentsBridge {

    public static let shared = AppIntentsBridge()

    /// The app's publish manager, so a broadcast started from Siri is
    /// the same one the Discover tab shows and can stop.
    @ObservationIgnored
    public var publishManager: (any BonjourPublishManagerProtocol)?

    /// Builds an explainer for the AI backend selected in Settings.
    @ObservationIgnored
    public var makeExplainer: (@MainActor () -> (any BonjourServiceExplainerProtocol)?)?

    /// Called after Siri starts a broadcast.
    @ObservationIgnored
    public var didPublish: (@MainActor (BonjourService) -> Void)?

    /// Called after Siri stops every broadcast.
    @ObservationIgnored
    public var didStopAllBroadcasts: (@MainActor () -> Void)?

    /// The service Open in KozBon is waiting to show. Observed by the
    /// root scene, which consumes it.
    public private(set) var pendingOpenRequest: OpenServiceRequest?

    public init() {}

    /// Asks the app to show a service. Called by Open in KozBon.
    public func requestOpen(_ request: OpenServiceRequest) {
        pendingOpenRequest = request
    }

    /// Returns the pending request and clears it, so it's handled once.
    public func consumeOpenRequest() -> OpenServiceRequest? {
        let request = pendingOpenRequest
        pendingOpenRequest = nil
        return request
    }
}
