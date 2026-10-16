//
//  AIBackendAvailability.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Observation
import StoreKit

// MARK: - AIBackendAvailability

/// Which ``AIBackend`` cases the current App Store storefront may
/// offer.
///
/// The China mainland storefront offers only Apple Intelligence.
/// China requires public generative-AI services to be filed with the
/// regulator, and none of KozBon's cloud providers are. App Review
/// rejected 4.8 under Guideline 5 for ChatGPT-associated features, and
/// naming any unfiled provider carries the same risk.
///
/// Keyed on the App Store storefront rather than the device locale:
/// the storefront is what the rule attaches to, and a Chinese-locale
/// user on the U.S. store is unaffected. An unknown storefront
/// (before StoreKit answers, or a build StoreKit can't place)
/// offers every backend, so nobody else loses a provider on a slow
/// launch.
@MainActor
@Observable
public final class AIBackendAvailability {

    /// ISO 3166-1 alpha-3 code of the China mainland storefront, as
    /// reported by `Storefront.countryCode`.
    public nonisolated static let chinaMainlandStorefront = "CHN"

    /// The current storefront's ISO 3166-1 alpha-3 country code, or
    /// `nil` until StoreKit reports one.
    public private(set) var storefrontCountryCode: String?

    public init(storefrontCountryCode: String? = nil) {
        self.storefrontCountryCode = storefrontCountryCode
    }

    // MARK: - Queries

    /// Whether `backend` may be offered on the current storefront.
    public func isOffered(_ backend: AIBackend) -> Bool {
        Self.isOffered(backend, inStorefront: storefrontCountryCode)
    }

    /// The backends to list in Settings, in declaration order.
    public var offeredBackends: [AIBackend] {
        AIBackend.allCases.filter { isOffered($0) }
    }

    /// Whether any cloud backend is offered. When none is, release
    /// notes naming a cloud AI provider are hidden as well.
    public var offersCloudProviders: Bool {
        AIBackend.allCases.contains { $0.isCloud && isOffered($0) }
    }

    /// Whether `backend` may be offered on the storefront with the
    /// given country code. A `nil` storefront offers everything.
    public nonisolated static func isOffered(_ backend: AIBackend, inStorefront countryCode: String?) -> Bool {
        switch backend {
        case .appleIntelligence:
            return true
        case .anthropic, .gemini, .openai:
            return countryCode?.uppercased() != chinaMainlandStorefront
        }
    }

    // MARK: - Updates

    /// Records the storefront's country code.
    public func update(storefrontCountryCode: String?) {
        guard storefrontCountryCode != self.storefrontCountryCode else { return }
        self.storefrontCountryCode = storefrontCountryCode
    }

    /// Reads the current storefront, then follows StoreKit's
    /// storefront updates until the calling task is cancelled.
    ///
    /// Intended for a SwiftUI `.task`, which cancels it with the
    /// scene.
    public func monitorStorefront() async {
        if let storefront = await Storefront.current {
            update(storefrontCountryCode: storefront.countryCode)
        }
        for await storefront in Storefront.updates {
            if Task.isCancelled { break }
            update(storefrontCountryCode: storefront.countryCode)
        }
    }
}
