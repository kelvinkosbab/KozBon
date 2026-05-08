//
//  BonjourServiceSortTypeTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourModels

// MARK: - BonjourServiceSortTypeTests

@Suite("BonjourServiceSortType")
struct BonjourServiceSortTypeTests {

    // MARK: - CaseIterable

    @Test("`allCases` exposes all 9 sort/filter options the menu UI relies on")
    func allCasesContainsNineOptions() {
        #expect(BonjourServiceSortType.allCases.count == 9)
    }

    // MARK: - ID

    @Test("Every case has a unique `id` so SwiftUI selection bindings stay unambiguous")
    func allIDsAreUnique() {
        let ids = BonjourServiceSortType.allCases.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("`.hostNameAsc.id` is the persisted `hostNameAsc` token")
    func hostNameAscID() {
        #expect(BonjourServiceSortType.hostNameAsc.id == "hostNameAsc")
    }

    @Test("`.hostNameDesc.id` is the persisted `hostNameDesc` token")
    func hostNameDescID() {
        #expect(BonjourServiceSortType.hostNameDesc.id == "hostNameDesc")
    }

    @Test("`.serviceNameAsc.id` is the persisted `serviceNameAsc` token")
    func serviceNameAscID() {
        #expect(BonjourServiceSortType.serviceNameAsc.id == "serviceNameAsc")
    }

    @Test("`.serviceNameDesc.id` is the persisted `serviceNameDesc` token")
    func serviceNameDescID() {
        #expect(BonjourServiceSortType.serviceNameDesc.id == "serviceNameDesc")
    }

    @Test("`.smartHome.id` is the persisted `smartHome` token")
    func smartHomeID() {
        #expect(BonjourServiceSortType.smartHome.id == "smartHome")
    }

    @Test("`.appleDevices.id` is the persisted `appleDevices` token")
    func appleDevicesID() {
        #expect(BonjourServiceSortType.appleDevices.id == "appleDevices")
    }

    @Test("`.mediaAndStreaming.id` is the persisted `mediaAndStreaming` token")
    func mediaAndStreamingID() {
        #expect(BonjourServiceSortType.mediaAndStreaming.id == "mediaAndStreaming")
    }

    @Test("`.printersAndScanners.id` is the persisted `printersAndScanners` token")
    func printersAndScannersID() {
        #expect(BonjourServiceSortType.printersAndScanners.id == "printersAndScanners")
    }

    @Test("`.remoteAccess.id` is the persisted `remoteAccess` token")
    func remoteAccessID() {
        #expect(BonjourServiceSortType.remoteAccess.id == "remoteAccess")
    }

    @Test("Each case can be recovered from its `id` via `allCases` lookup")
    func allIDsRoundTripViaLookup() {
        for sortType in BonjourServiceSortType.allCases {
            let found = BonjourServiceSortType.allCases.first { $0.id == sortType.id }
            #expect(found == sortType)
        }
    }

    // MARK: - Titles

    @Test("Every case has a non-empty `title` so the picker never shows a blank row")
    func allTitlesAreNonEmpty() {
        for sortType in BonjourServiceSortType.allCases {
            #expect(!sortType.title.isEmpty)
        }
    }

    // MARK: - Icon Names

    @Test("Every case has a non-empty `iconName` so each menu row renders a symbol")
    func allIconNamesAreNonEmpty() {
        for sortType in BonjourServiceSortType.allCases {
            #expect(!sortType.iconName.isEmpty)
        }
    }

    // MARK: - isFilter

    @Test("Pure ordering options (host/service name asc & desc) report `isFilter == false`")
    func sortOptionsAreNotFilters() {
        #expect(!BonjourServiceSortType.hostNameAsc.isFilter)
        #expect(!BonjourServiceSortType.hostNameDesc.isFilter)
        #expect(!BonjourServiceSortType.serviceNameAsc.isFilter)
        #expect(!BonjourServiceSortType.serviceNameDesc.isFilter)
    }

    @Test("Category-narrowing options (smart home, devices, etc.) report `isFilter == true`")
    func filterOptionsAreFilters() {
        #expect(BonjourServiceSortType.smartHome.isFilter)
        #expect(BonjourServiceSortType.appleDevices.isFilter)
        #expect(BonjourServiceSortType.mediaAndStreaming.isFilter)
        #expect(BonjourServiceSortType.printersAndScanners.isFilter)
        #expect(BonjourServiceSortType.remoteAccess.isFilter)
    }
}
