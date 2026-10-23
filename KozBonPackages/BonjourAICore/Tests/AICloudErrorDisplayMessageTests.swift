//
//  AICloudErrorDisplayMessageTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourLocalization
@testable import BonjourAICore

// MARK: - AICloudErrorDisplayMessageTests

@Suite("AICloudError.displayMessage")
struct AICloudErrorDisplayMessageTests {

    private var offlineMessage: String {
        String(localized: Strings.Connectivity.requestFailed)
    }

    @Test("A network failure shows the localized connection message")
    func networkUnavailable() {
        #expect(AICloudError.displayMessage(for: AICloudError.networkUnavailable) == offlineMessage)
    }

    @Test("A raw offline URL error shows the localized connection message")
    func offlineURLError() {
        #expect(AICloudError.displayMessage(for: URLError(.notConnectedToInternet)) == offlineMessage)
    }

    @Test("Other errors keep their own description")
    func otherErrors() {
        let error = AICloudError.rateLimited(provider: .anthropic, retryAfterSeconds: nil)
        #expect(AICloudError.displayMessage(for: error) == error.localizedDescription)
    }
}
