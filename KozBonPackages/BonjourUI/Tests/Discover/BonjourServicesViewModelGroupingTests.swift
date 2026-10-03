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

/// Pins how the Nearby list breaks into sections and how those
/// sections are ordered.
///
/// The rule under test: section along whatever axis the user's sort
/// already clusters — per service type for the service-type sorts
/// (and the default), per host for the host-name sorts. Category
/// filters stay flat, the list already being scoped to one bucket.
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

    @Test("With nothing applied, the list groups by host — matching the Host name A → Z the menu shows checked")
    func groupsByHostWhenNothingApplied() {
        let viewModel = makeViewModel()
        #expect(viewModel.sortType == nil)
        #expect(viewModel.serviceGrouping == .hostName)
    }

    @Test("The default layout is identical to explicitly picking Host name A → Z")
    func defaultMatchesHostNameAscending() {
        // Settings stores `nil` for a Host name A → Z default, so a
        // mismatch here means the user has to re-tap the option the
        // menu already shows as selected.
        let viewModel = makePopulatedViewModel()
        let defaultTitles = viewModel.groupedActiveServices.map(\.title)
        viewModel.sort(sortType: .hostNameAsc)
        #expect(viewModel.groupedActiveServices.map(\.title) == defaultTitles)
    }

    @Test("Grouping is on for both service-type sorts")
    func groupsForServiceTypeSorts() {
        let viewModel = makeViewModel()
        viewModel.sort(sortType: .serviceNameAsc)
        #expect(viewModel.serviceGrouping == .serviceType)
        viewModel.sort(sortType: .serviceNameDesc)
        #expect(viewModel.serviceGrouping == .serviceType)
    }

    @Test("Host-name sorts group by host, the axis they already cluster on")
    func groupsByHostForHostNameSorts() {
        let viewModel = makeViewModel()
        viewModel.sort(sortType: .hostNameAsc)
        #expect(viewModel.serviceGrouping == .hostName)
        viewModel.sort(sortType: .hostNameDesc)
        #expect(viewModel.serviceGrouping == .hostName)
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
        #expect(viewModel.serviceGrouping == .flat)
    }

    @Test("A flat state yields no groups at all, so the view never builds both branches")
    func flatStateReturnsNoGroups() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .mediaAndStreaming)
        #expect(viewModel.serviceGrouping == .flat)
        #expect(viewModel.groupedActiveServices.isEmpty)
    }

    // MARK: - Bucketing

    @Test("Services bucket into one group per service type")
    func bucketsByServiceType() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .serviceNameAsc)
        let groups = viewModel.groupedActiveServices

        #expect(groups.count == 2)
        #expect(groups.map(\.title) == ["AirPlay", "Printer"])
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
        viewModel.sort(sortType: .serviceNameAsc)
        let ids = viewModel.groupedActiveServices.map(\.id)
        // Unique ids matter: `ForEach` silently drops rows on a
        // collision, which a display-name key would invite.
        #expect(Set(ids).count == ids.count)
        let carriesTransport = ids.allSatisfy { $0.contains("_tcp") }
        #expect(carriesTransport)
    }

    // MARK: - Ordering

    @Test("The ascending service-type sort orders groups alphabetically by type name")
    func ascendingSortOrdersGroupsAlphabetically() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .serviceNameAsc)
        #expect(viewModel.groupedActiveServices.map(\.title) == ["AirPlay", "Printer"])
    }

    @Test("The descending service-type sort reverses the group order")
    func descendingSortReversesGroups() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .serviceNameDesc)
        #expect(viewModel.groupedActiveServices.map(\.title) == ["Printer", "AirPlay"])
    }

    @Test("Within a group, rows keep the order the active sort produced")
    func withinGroupOrderFollowsActiveSort() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .serviceNameAsc)
        // Ties on type break by instance name, so the AirPlay bucket
        // reads Attic before Bedroom.
        let airPlay = viewModel.groupedActiveServices.first { $0.title == "AirPlay" }
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

        viewModel.sort(sortType: .serviceNameAsc)
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
        viewModel.sort(sortType: .serviceNameAsc)
        let group = try #require(viewModel.groupedActiveServices.first)
        #expect(group.footerDetail == nil)
    }

    // MARK: - Host Grouping

    @Test("Services bucket into one group per host")
    func bucketsByHost() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .hostNameAsc)
        let groups = viewModel.groupedActiveServices

        // Attic and Bedroom each advertise AirPlay; Office is the
        // printer. Unresolved hosts fall back to the instance name.
        #expect(groups.count == 3)
        #expect(groups.map(\.title) == ["Attic", "Bedroom", "Office"])
        #expect(groups.allSatisfy { $0.services.count == 1 })
    }

    @Test("Host groups are keyed as host groups, so rows know which half to drop")
    func hostGroupsCarryTheHostKey() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .hostNameAsc)
        #expect(viewModel.groupedActiveServices.allSatisfy { $0.key == .hostName })
    }

    @Test("Several services on one host collapse into a single section")
    func oneSectionPerHostNotPerService() throws {
        let viewModel = makeViewModel()
        viewModel.didAdd(service: makeService(named: "Studio", typeName: "AirPlay", type: "airplay"))
        viewModel.didAdd(service: makeService(named: "Studio", typeName: "Printer", type: "ipp"))
        viewModel.sort(sortType: .hostNameAsc)

        let groups = viewModel.groupedActiveServices
        #expect(groups.count == 1)
        let studio = try #require(groups.first)
        #expect(studio.title == "Studio")
        #expect(studio.services.count == 2)
        // Within a host, the sort's tie-break orders by type name.
        #expect(studio.services.map(\.serviceType.name) == ["AirPlay", "Printer"])
    }

    @Test("The descending host sort reverses the section order")
    func descendingHostSortReversesSections() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .hostNameDesc)
        #expect(viewModel.groupedActiveServices.map(\.title) == ["Office", "Bedroom", "Attic"])
    }

    @Test("Host sections carry no footer — a host spans several types")
    func hostGroupsHaveNoFooter() {
        let viewModel = makeViewModel()
        viewModel.didAdd(
            service: makeService(
                named: "Studio",
                typeName: "AirPlay",
                type: "airplay",
                detail: "Protocol for streaming audio / video content"
            )
        )
        viewModel.sort(sortType: .hostNameAsc)

        #expect(viewModel.groupedActiveServices.allSatisfy { $0.footerDetail == nil })
    }

    @Test("Every discovered service lands in exactly one host group")
    func hostGroupingLosesNothing() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .hostNameAsc)
        let grouped = viewModel.groupedActiveServices.flatMap(\.services)
        #expect(Set(grouped.map(\.id)) == Set(viewModel.flatActiveServices.map(\.id)))
    }

    @Test("Host group ids are unique, so no section silently drops")
    func hostGroupIdsAreUnique() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .hostNameAsc)
        let ids = viewModel.groupedActiveServices.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - Search Composition

    @Test("Search narrows within groups and drops groups that empty out")
    func searchComposesWithGrouping() {
        let viewModel = makePopulatedViewModel()
        viewModel.sort(sortType: .serviceNameAsc)
        viewModel.searchText = "Attic"

        let groups = viewModel.groupedActiveServices
        #expect(groups.count == 1)
        #expect(groups.first?.title == "AirPlay")
        #expect(groups.first?.services.map(\.service.name) == ["Attic"])
    }

    // MARK: - Empty

    @Test("No discovered services means no groups")
    func emptyProducesNoGroups() {
        let viewModel = makeViewModel()
        #expect(viewModel.groupedActiveServices.isEmpty)
    }
}
