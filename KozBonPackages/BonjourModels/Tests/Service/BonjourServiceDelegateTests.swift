//
//  BonjourServiceDelegateTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourModels
import BonjourCore

// MARK: - TestNetServiceDelegate

@MainActor
private final class TestNetServiceDelegate: MyNetServiceDelegate {
    var resolvedServices: [BonjourService] = []
    func serviceDidResolveAddress(_ service: BonjourService) {
        resolvedServices.append(service)
    }
}

// MARK: - BonjourServiceDelegateTests

@Suite("BonjourService Delegate & State Machine")
@MainActor
struct BonjourServiceDelegateTests {

    // MARK: - Helpers

    private func makeService(
        name: String = "Test",
        type: String = "http"
    ) -> BonjourService {
        let serviceType = BonjourServiceType(name: "HTTP", type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    // MARK: - Resolve State

    @Test("`resolve()` flips `isResolving` to true so the UI can show a spinner")
    func resolveChangesIsResolvingToTrue() {
        let service = makeService()
        service.resolve()
        #expect(service.isResolving == true)
    }

    @Test("`stop()` clears both `isResolving` and `isPublishing` to a clean idle state")
    func stopResetsState() {
        let service = makeService()
        service.resolve()
        service.stop()
        #expect(service.isResolving == false)
        #expect(service.isPublishing == false)
    }

    @Test("`stop(completion:)` invokes the callback once `NetService` reports it has stopped")
    func stopCallsDidStopCallback() {
        let service = makeService()
        var callbackCalled = false
        service.stop {
            callbackCalled = true
        }
        // Simulate NetService calling back
        service.netServiceDidStop(service.service)
        #expect(callbackCalled == true)
    }

    // MARK: - Resolve Delegate Callbacks

    @Test("`netServiceDidResolveAddress` notifies the registered delegate on success")
    func netServiceDidResolveAddressCallsDelegate() {
        let service = makeService()
        let delegate = TestNetServiceDelegate()
        service.delegate = delegate

        service.netServiceDidResolveAddress(service.service)

        #expect(delegate.resolvedServices.count == 1)
    }

    @Test("Successful resolution clears `isResolving` so the spinner stops")
    func netServiceDidResolveAddressSetsIsResolvingFalse() {
        let service = makeService()
        service.resolve()
        #expect(service.isResolving == true)

        service.netServiceDidResolveAddress(service.service)
        #expect(service.isResolving == false)
    }

    @Test("Failed resolution still notifies the delegate so the UI can react")
    func netServiceDidNotResolveCallsDelegate() {
        let service = makeService()
        let delegate = TestNetServiceDelegate()
        service.delegate = delegate

        service.netService(service.service, didNotResolve: [:])

        #expect(delegate.resolvedServices.count == 1)
    }

    @Test("Failed resolution clears `isResolving` so the spinner stops")
    func netServiceDidNotResolveSetsIsResolvingFalse() {
        let service = makeService()
        service.resolve()
        #expect(service.isResolving == true)

        service.netService(service.service, didNotResolve: [:])
        #expect(service.isResolving == false)
    }

    // MARK: - Publish Delegate Callbacks

    @Test("Successful publish clears `isPublishing` once the system confirms registration")
    func netServiceDidPublishSetsIsPublishingFalse() {
        let service = makeService()
        // Directly call the delegate method to test state transition
        service.netServiceDidPublish(service.service)
        #expect(service.isPublishing == false)
    }

    @Test("Failed publish clears `isPublishing` so the UI doesn't get stuck in a publishing state")
    func netServiceDidNotPublishSetsIsPublishingFalse() {
        let service = makeService()
        service.netService(service.service, didNotPublish: [:])
        #expect(service.isPublishing == false)
    }

    // MARK: - Monitoring

    @Test("`startMonitoring()` is safe to call without an active resolver")
    func startMonitoringDoesNotCrash() {
        let service = makeService()
        service.startMonitoring()
        // If we reach here without crashing, the test passes
    }

    @Test("`stopMonitoring()` is safe to call when monitoring was never started")
    func stopMonitoringDoesNotCrash() {
        let service = makeService()
        service.stopMonitoring()
        // If we reach here without crashing, the test passes
    }

    // MARK: - TXT Record Updates

    @Test("TXT record updates are parsed into `dataRecords` and sorted by key")
    func netServiceDidUpdateTXTRecordParsesRecords() {
        let service = makeService()

        let txtData = NetService.data(fromTXTRecord: [
            "key1": Data("value1".utf8),
            "key2": Data("value2".utf8)
        ])

        service.netService(service.service, didUpdateTXTRecord: txtData)

        #expect(service.dataRecords.count == 2)
        // Records should be sorted by key
        #expect(service.dataRecords[0].key == "key1")
        #expect(service.dataRecords[0].value == "value1")
        #expect(service.dataRecords[1].key == "key2")
        #expect(service.dataRecords[1].value == "value2")
    }
}
