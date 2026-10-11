//
//  BroadcastServiceIntentTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning
@testable import BonjourAppIntents

// MARK: - BroadcastServiceIntentTests

@Suite("BroadcastServiceIntent")
@MainActor
struct BroadcastServiceIntentTests {

    /// The built-in types only; the full lookup also reads Core Data,
    /// which `swift test` can't load.
    private let library = BonjourServiceType.serviceTypeLibrary

    private struct PublishError: Error {}

    /// Collects what the bridge's callbacks report.
    @MainActor
    private final class Recorder {
        var published: [BonjourService] = []
        var stopped = false
    }

    private func makeBridge() -> (AppIntentsBridge, MockBonjourPublishManager) {
        let bridge = AppIntentsBridge()
        let publishManager = MockBonjourPublishManager()
        bridge.publishManager = publishManager
        return (bridge, publishManager)
    }

    @Test("Broadcasting publishes the type and tells the app")
    func publishes() async throws {
        let (bridge, publishManager) = makeBridge()
        let recorder = Recorder()
        bridge.didPublish = { recorder.published.append($0) }

        let reply = try await BroadcastServiceIntent.broadcast(fullType: "_http._tcp", port: 8080, bridge: bridge, serviceTypes: library)

        #expect(publishManager.publishCallCount == 1)
        #expect(recorder.published.count == 1)
        #expect(reply == Strings.Siri.broadcastStarted("Hypertext Transfer Protocol (HTTP)", port: "8080"))
    }

    @Test("A UDP type is refused")
    func refusesUDP() async {
        let (bridge, publishManager) = makeBridge()
        let error = await #expect(throws: SiriIntentError.self) {
            try await BroadcastServiceIntent.broadcast(fullType: "_airplay._udp", port: 8080, bridge: bridge, serviceTypes: library)
        }
        #expect(error?.message == Strings.Siri.broadcastTCPOnly)
        #expect(publishManager.publishCallCount == 0)
    }

    @Test("A port below the minimum is refused")
    func refusesLowPort() async {
        let (bridge, _) = makeBridge()
        let error = await #expect(throws: SiriIntentError.self) {
            try await BroadcastServiceIntent.broadcast(fullType: "_http._tcp", port: 80, bridge: bridge, serviceTypes: library)
        }
        #expect(error?.message == Strings.Errors.portMin(Constants.Network.minimumPort))
    }

    @Test("Without the app's publish manager, Siri asks to open the app")
    func needsApp() async {
        let error = await #expect(throws: SiriIntentError.self) {
            try await BroadcastServiceIntent.broadcast(
                fullType: "_http._tcp",
                port: 8080,
                bridge: AppIntentsBridge(),
                serviceTypes: library
            )
        }
        #expect(error?.message == Strings.Siri.openAppAndRetry)
    }

    @Test("A failed publish is reported")
    func reportsFailure() async {
        let (bridge, publishManager) = makeBridge()
        publishManager.shouldSucceed = false
        publishManager.errorToThrow = PublishError()
        await #expect(throws: SiriIntentError.self) {
            try await BroadcastServiceIntent.broadcast(fullType: "_http._tcp", port: 8080, bridge: bridge, serviceTypes: library)
        }
    }

    @Test("Stopping unpublishes everything and tells the app")
    func stopsAll() async throws {
        let (bridge, publishManager) = makeBridge()
        let recorder = Recorder()
        bridge.didStopAllBroadcasts = { recorder.stopped = true }
        _ = try await BroadcastServiceIntent.broadcast(fullType: "_http._tcp", port: 8080, bridge: bridge, serviceTypes: library)

        let reply = await StopBroadcastingIntent.stopAll(bridge: bridge)

        #expect(publishManager.publishedServices.isEmpty)
        #expect(recorder.stopped)
        #expect(reply == Strings.Siri.stoppedBroadcasts(1))
    }

    @Test("Stopping with nothing broadcasting says so")
    func nothingToStop() async {
        let (bridge, _) = makeBridge()
        #expect(await StopBroadcastingIntent.stopAll(bridge: bridge) == Strings.Siri.noBroadcasts)
    }
}
