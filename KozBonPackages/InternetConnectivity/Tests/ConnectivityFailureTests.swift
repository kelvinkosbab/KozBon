//
//  ConnectivityFailureTests.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import InternetConnectivity

// MARK: - ConnectivityFailureTests

@Suite("ConnectivityFailure")
struct ConnectivityFailureTests {

    @Test("Connectivity URL errors count as offline", arguments: [
        URLError.Code.notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .cannotFindHost,
        .cannotConnectToHost,
        .timedOut
    ])
    func offlineCodes(code: URLError.Code) {
        #expect(ConnectivityFailure.isOffline(URLError(code)))
    }

    @Test("Server and request URL errors don't count as offline", arguments: [
        URLError.Code.badServerResponse,
        .badURL,
        .userAuthenticationRequired,
        .cancelled,
        .serverCertificateUntrusted
    ])
    func nonOfflineCodes(code: URLError.Code) {
        #expect(!ConnectivityFailure.isOffline(URLError(code)))
    }

    @Test("Non-URL errors don't count as offline")
    func nonURLErrors() {
        #expect(!ConnectivityFailure.isOffline(CancellationError()))
    }
}
