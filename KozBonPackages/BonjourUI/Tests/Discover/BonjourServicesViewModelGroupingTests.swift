//
//  BonjourServicesViewModelGroupingTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourModels
import BonjourScanning
@testable import BonjourUI

// MARK: - BonjourServicesViewModelGroupingTests

/// Pins when the Nearby list breaks into per-service-type sections
/// and how those sections are ordered.
///
/// The rule under test: group when the user hasn't asked for a
/// competing order — i.e. nothing applied, or an explicit
/// service-type sort. Host-name sorts and category filters stay
/// flat.
@Suite("BonjourServicesViewModel · Grouping")
@MainActor
struct BonjourServicesViewModelGroupingTests {

    // MARK: - Helpers

    private func makeViewModel() -> BonjourServicesViewModel {
        BonjourServicesViewModel(
            serviceScanner: MockBonjourServiceScanner(),
            publishManager: MockBonjourPublishManager(),
            localNetworkMonitor: MockLocalNetworkMonitor()
        )
    }

    /// Distinct instance name and type name — the shared helper in
    /// the sibling suite reuses one string for both, which would
    /// hide ordering bugs here.
    private func makeService(
        named instanceName: String,
        typeName: String,
        type: String,
        detail: String? = nil
    ) -> BonjourService {
        let serviceType = BonjourServiceType(
            name: typeName,
            type: type,
            transportLayer: .tcp,
            detail: detail
        )
        return BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: instanceName,
                port: 8080
            ),
            serviceType: serviceType
        )
    }

    /// Two AirPlay instances, one printer — enough to prove both
    /// bucketing and within-bucket ordering.
    private func makePopulatedViewModel() -> BonjourServicesViewModel {
        let viewModel = makeViewModel()
        viewModel.didAdd(service: makeService(named: "Bedroom", typeName: "AirPlay", type: "airplay"))
        viewModel.didAdd(service: makeService(named: "Office", typeName: "Printer", type: "ipp"))
        viewModel.didAdd(service: makeService(named: "Attic", typeName: "AirPlay", type: "airplay"))
        return viewModel
    }

    // MARK: - When Grouping Applies

    @Test("Grouping is on by default, with nothing applied")
    func groupsWhenNothingApplied() {
        let viewModel = makeViewModel()
        #expect(viewModel.sortType == nil)
        #expect(viewModel.isGroupedByServiceType)
    }

    @Test("Grouping is on for both service-type sorts")
    func groupsForServiceTypeSorts() {
        let viewModel = makeViewModel()
        viewModel.sort(sortType: .serviceNameAsc)
        #expect(viewModel.isGroupedByServiceType)
        viewModel.sort(sortType: .serviceNameDesc)
        #expect(viewModel.isGroupedByServiceType)
    }

    @Test("Grouping is off for host-name sorts — sections would fight an A→Z hostname run")
    func staysFlatForHostNameSorts() {
        let viewModel = makeViewModel()
        viewModel.sort(sortType: .hostNameAsc)
        #expect(!viewModel.isGroupedByServiceType)
        viewModel.sort(sortType: .hostNameDesc)
        #expect(!viewModel.isGroupedByServiceType)
    }

    @Test("Grouping is off for every category filter — the list is already scoped", arguments: [
        BonjourServiceSortType.smartHome,
        .appleDevices,
        .mediaAndStreaming,
        .printersAndScanners,
        .remoteAccess
    ])
    func staysFlatForCategoryFilters(_ filter: BonjourServiceSortType) {
        let viewModel = makeViewModel()
        viewModel.sort(sortType: filter)
        #expect(!viewModel.isGroupedByServiceType)
    }

    @Test("A non-grouping state yields no groups at all, so the view never builds both branches")
    func nonGroupingStateReturnsNoGroups() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .hostNameAsc)
        #expect(viewModel.groupedActiveServices.isEmpty)
        #expect(!viewModel.flatActiveServices.isEmpty)
    }

    // MARK: - Bucketing

    @Test("Services bucket into one group per service type")
    func bucketsByServiceType() {
        let viewModel = makePopulatedViewModel()
        let groups = viewModel.groupedActiveServices

        #expect(groups.count == 2)
        #expect(groups.map(\.serviceType.name) == ["AirPlay", "Printer"])
        #expect(groups.first?.services.count == 2)
        #expect(groups.last?.services.count == 1)
    }

    @Test("Every discovered service lands in exactly one group")
    func groupingLosesNothing() {
        let viewModel = makePopulatedViewModel()
        let grouped = viewModel.groupedActiveServices.flatMap(\.services)
        #expect(grouped.count == viewModel.flatActiveServices.count)
        #expect(Set(grouped.map(\.id)) == Set(viewModel.flatActiveServices.map(\.id)))
    }

    @Test("Group id is the full type, so same-named types across transports stay distinct")
    func groupIdIsFullType() {
        let viewModel = makePopulatedViewModel()
        let ids = viewModel.groupedActiveServices.map(\.id)
        // Unique ids matter: `ForEach` silently drops rows on a
        // collision, which a display-name key would invite.
        #expect(Set(ids).count == ids.count)
        let carriesTransport = ids.allSatisfy { $0.contains("_tcp") }
        #expect(carriesTransport)
    }

    // MARK: - Ordering

    @Test("Groups are alphabetical by type name with nothing applied")
    func groupsAlphabeticalByDefault() {
        let viewModel = makePopulatedViewModel()
        #expect(viewModel.groupedActiveServices.map(\.serviceType.name) == ["AirPlay", "Printer"])
    }

    @Test("The descending service-type sort reverses the group order")
    func descendingSortReversesGroups() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .serviceNameDesc)
        #expect(viewModel.groupedActiveServices.map(\.serviceType.name) == ["Printer", "AirPlay"])
    }

    @Test("Within a group, rows keep the order the active sort produced")
    func withinGroupOrderFollowsActiveSort() {
        let viewModel = makePopulatedViewModel()
        // Default sorts by instance name, so the AirPlay bucket
        // reads Attic before Bedroom.
        let airPlay = viewModel.groupedActiveServices.first { $0.serviceType.name == "AirPlay" }
        #expect(airPlay?.services.map(\.service.name) == ["Attic", "Bedroom"])
    }

    // MARK: - Section Footer

    @Test("A type with a description exposes it as the section footer")
    func footerCarriesServiceTypeDetail() throws {
        let viewModel = makeViewModel()
        viewModel.didAdd(
            service: makeService(
                named: "Bedroom",
                typeName: "AirPlay",
                type: "airplay",
                detail: "Protocol for streaming audio / video content"
            )
        )

        let group = try #require(viewModel.groupedActiveServices.first)
        #expect(group.footerDetail == "Protocol for streaming audio / video content")
    }

    @Test("A type with no description yields no footer", arguments: [nil, ""])
    func footerIsAbsentWithoutADetail(_ detail: String?) throws {
        let viewModel = makeViewModel()
        viewModel.didAdd(
            service: makeService(
                named: "Office",
                typeName: "Printer",
                type: "ipp",
                detail: detail
            )
        )

        // The empty string is normalized away too — an empty footer
        // still draws its padding.
        let group = try #require(viewModel.groupedActiveServices.first)
        #expect(group.footerDetail == nil)
    }

    // MARK: - Search Composition

    @Test("Search narrows within groups and drops groups that empty out")
    func searchComposesWithGrouping() {
        let viewModel = makePopulatedViewModel()
        viewModel.searchText = "Attic"

        let groups = viewModel.groupedActiveServices
        #expect(groups.count == 1)
        #expect(groups.first?.serviceType.name == "AirPlay")
        #expect(groups.first?.services.map(\.service.name) == ["Attic"])
    }

    // MARK: - Empty

    @Test("No discovered services means no groups")
    func emptyProducesNoGroups() {
        let viewModel = makeViewModel()
        #expect(viewModel.isGroupedByServiceType)
        #expect(viewModel.groupedActiveServices.isEmpty)
    }
}
