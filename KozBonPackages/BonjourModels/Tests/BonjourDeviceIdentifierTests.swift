//
//  BonjourDeviceIdentifierTests.swift
//  BonjourModels
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourModels

// MARK: - BonjourDeviceIdentifierTests

/// Pin the deterministic Apple device-identification surface. Every
/// strategy here is a candidate for fallback when the AI Insights
/// path can't reliably identify a device, so regressions need to fail
/// loudly.
@Suite("BonjourDeviceIdentifier")
struct BonjourDeviceIdentifierTests {

    // MARK: - Helpers

    private func txt(_ pairs: [String: String]) -> [BonjourService.TxtDataRecord] {
        pairs.map { BonjourService.TxtDataRecord(key: $0.key, value: $0.value) }
    }

    private func identify(
        txt records: [BonjourService.TxtDataRecord] = [],
        hostname: String = "",
        serviceName: String = ""
    ) -> DeviceIdentification? {
        BonjourDeviceIdentifier.identify(
            txtRecords: records,
            hostname: hostname,
            serviceName: serviceName
        )
    }

    // MARK: - TXT-Record Apple Model Lookup

    @Test("`model=iPhone16,1` resolves to iPhone 15 Pro (high confidence)")
    func iPhoneModelTxtResolvesHighConfidence() {
        let result = identify(txt: txt(["model": "iPhone16,1"]))
        #expect(result?.friendlyName == "iPhone 15 Pro")
        #expect(result?.category == .phone)
        #expect(result?.confidence == .high)
    }

    @Test("`model=iPhone17,1` resolves to iPhone 16 Pro")
    func iPhone16ProResolves() {
        let result = identify(txt: txt(["model": "iPhone17,1"]))
        #expect(result?.friendlyName == "iPhone 16 Pro")
        #expect(result?.category == .phone)
    }

    @Test("`model=AppleTV14,1` resolves to Apple TV 4K (3rd generation)")
    func appleTV4K3rdGenResolves() {
        let result = identify(txt: txt(["model": "AppleTV14,1"]))
        #expect(result?.friendlyName == "Apple TV 4K (3rd generation)")
        #expect(result?.category == .tv)
        #expect(result?.confidence == .high)
    }

    @Test("`model=AudioAccessory6,1` resolves to HomePod (2nd generation)")
    func homePod2ndGenResolves() {
        let result = identify(txt: txt(["model": "AudioAccessory6,1"]))
        #expect(result?.friendlyName == "HomePod (2nd generation)")
        #expect(result?.category == .speaker)
    }

    @Test("`model=AudioAccessory5,1` resolves to HomePod mini")
    func homePodMiniResolves() {
        let result = identify(txt: txt(["model": "AudioAccessory5,1"]))
        #expect(result?.friendlyName == "HomePod mini")
        #expect(result?.category == .speaker)
    }

    @Test("`model=Mac15,12` resolves to a MacBook Air 13\" (M3) in the computer category")
    func macBookAirM3Resolves() {
        let result = identify(txt: txt(["model": "Mac15,12"]))
        #expect(result?.friendlyName == "MacBook Air 13\" (M3)")
        #expect(result?.category == .computer)
    }

    @Test("`model=iPad14,1` resolves to iPad mini (6th generation)")
    func iPadMini6thGenResolves() {
        let result = identify(txt: txt(["model": "iPad14,1"]))
        #expect(result?.friendlyName == "iPad mini (6th generation)")
        #expect(result?.category == .tablet)
    }

    @Test("`model=Watch7,5` resolves to Apple Watch Ultra 2")
    func appleWatchUltra2Resolves() {
        let result = identify(txt: txt(["model": "Watch7,5"]))
        #expect(result?.friendlyName == "Apple Watch Ultra 2")
        #expect(result?.category == .watch)
    }

    // MARK: - TXT Key Variants

    @Test("`mdl` key (used by Companion-Link / Sonos) is checked alongside `model`")
    func mdlKeyAlsoChecked() {
        let result = identify(txt: txt(["mdl": "iPhone16,1"]))
        #expect(result?.friendlyName == "iPhone 15 Pro")
    }

    @Test("`md` key (HomeKit's model description) is checked alongside `model`")
    func mdKeyAlsoChecked() {
        let result = identify(txt: txt(["md": "AppleTV14,1"]))
        #expect(result?.friendlyName == "Apple TV 4K (3rd generation)")
    }

    @Test("TXT-key match is case-insensitive (`MODEL` works the same as `model`)")
    func txtKeyMatchIsCaseInsensitive() {
        let result = identify(txt: txt(["MODEL": "iPhone16,1"]))
        #expect(result?.friendlyName == "iPhone 15 Pro")
    }

    @Test("Unknown wire identifier in TXT records produces no match")
    func unknownIdentifierInTxtReturnsNil() {
        let result = identify(txt: txt(["model": "iPhone99,99"]))
        #expect(result == nil)
    }

    @Test("Empty TXT record set with no hostname produces nil")
    func emptyInputReturnsNil() {
        #expect(identify() == nil)
    }

    // MARK: - Hostname Pattern Fallback

    @Test("Hostname `Kelvins-iPhone.local.` matches the iPhone family at medium confidence")
    func hostnameIPhoneMatchesFamily() {
        let result = identify(hostname: "Kelvins-iPhone.local.")
        #expect(result?.friendlyName == "iPhone")
        #expect(result?.category == .phone)
        #expect(result?.confidence == .medium)
    }

    @Test("Hostname `Living-Room-Apple-TV.local.` matches Apple TV family")
    func hostnameAppleTVMatches() {
        let result = identify(hostname: "Living-Room-Apple-TV.local.")
        #expect(result?.friendlyName == "Apple TV")
        #expect(result?.category == .tv)
    }

    @Test("Hostname `kitchen-homepod-mini.local.` matches HomePod mini before generic HomePod")
    func hostnameHomePodMiniMatchesBeforeHomePod() {
        // Pin the priority ordering: more specific patterns must win.
        // Without explicit ordering, "homepod" would match before
        // "homepod mini" and report the wrong device class.
        let result = identify(hostname: "kitchen-homepod-mini.local.")
        #expect(result?.friendlyName == "HomePod mini")
    }

    @Test("Hostname `office-macbook-pro.local.` matches MacBook Pro before generic MacBook")
    func hostnameMacBookProMatchesBeforeMacBook() {
        let result = identify(hostname: "office-macbook-pro.local.")
        #expect(result?.friendlyName == "MacBook Pro")
    }

    @Test("Hostname `studio.local.` matches Mac Studio")
    func hostnameMacStudioMatches() {
        let result = identify(hostname: "mac-studio.local.")
        #expect(result?.friendlyName == "Mac Studio")
    }

    @Test("Hostname `iMac-of-Kelvin.local.` matches iMac")
    func hostnameIMacMatches() {
        let result = identify(hostname: "iMac-of-Kelvin.local.")
        #expect(result?.friendlyName == "iMac")
        #expect(result?.category == .computer)
    }

    @Test("Hostname underscores are normalized — `kitchen_homepod.local.` matches HomePod")
    func hostnameUnderscoreNormalization() {
        let result = identify(hostname: "kitchen_homepod.local.")
        #expect(result?.friendlyName == "HomePod")
    }

    @Test("Service name (not hostname) carries the keyword: works the same as hostname")
    func serviceNameAlsoMatchesPatterns() {
        // The service.name is often the user-given device name on
        // Apple devices (e.g., AirPlay's name = "Living Room Apple TV").
        // The identifier checks both signals so a device with a
        // generic hostname but a meaningful service name still resolves.
        let result = identify(hostname: "device-1F2A.local.", serviceName: "Kelvin's iPad")
        #expect(result?.friendlyName == "iPad")
        #expect(result?.category == .tablet)
    }

    @Test("Hostname keyword match is case-insensitive (`IPHONE` works)")
    func hostnameKeywordCaseInsensitive() {
        let result = identify(hostname: "IPHONE.local.")
        #expect(result?.friendlyName == "iPhone")
    }

    // MARK: - Strategy Priority

    @Test("TXT model lookup wins over hostname — even when both match different devices")
    func txtLookupWinsOverHostnamePattern() {
        // Construct a contradiction: hostname says "iPad" but TXT
        // explicitly says iPhone 15 Pro. The TXT match is more
        // authoritative (someone explicitly published the model
        // string), so it wins.
        let result = identify(
            txt: txt(["model": "iPhone16,1"]),
            hostname: "shared-iPad.local."
        )
        #expect(result?.friendlyName == "iPhone 15 Pro")
        #expect(result?.confidence == .high)
    }

    @Test("Hostname pattern only resolves when TXT lookup fails")
    func hostnameFallsThroughWhenTxtMisses() {
        let result = identify(
            txt: txt(["model": "Some-Unrecognized-Identifier"]),
            hostname: "office-macbook.local."
        )
        #expect(result?.friendlyName == "MacBook")
        #expect(result?.confidence == .medium)
    }

    @Test("Non-Apple hostname produces nil — the identifier intentionally doesn't guess")
    func nonAppleHostnameReturnsNil() {
        // Sonos, Hue, Roku, etc. fall through. These can be added
        // in a follow-up; for now the AI Insights menu covers them.
        let result = identify(hostname: "sonos-living-room.local.")
        #expect(result == nil)
    }

    // MARK: - Category & Icons

    @Test("Every category has a non-empty SF Symbol icon name")
    func everyCategoryHasIcon() {
        for category in DeviceIdentification.Category.allCases {
            #expect(!category.iconName.isEmpty, "\(category) has empty iconName")
        }
    }

    @Test("Phone category uses the iPhone glyph; computer uses the laptop glyph")
    func categoryIconAssignmentsAreSensible() {
        #expect(DeviceIdentification.Category.phone.iconName == "iphone")
        #expect(DeviceIdentification.Category.computer.iconName == "laptopcomputer")
        #expect(DeviceIdentification.Category.tv.iconName == "appletv")
        #expect(DeviceIdentification.Category.speaker.iconName == "homepod")
        #expect(DeviceIdentification.Category.watch.iconName == "applewatch")
    }

    // MARK: - Lookup Table Sanity Checks

    @Test("Apple model lookup table has at least 80 entries to cover modern hardware")
    func lookupTableHasReasonableCoverage() {
        // Sanity-check coverage so a future "let me delete most of
        // the table" change is forced to be deliberate. The exact
        // number isn't important — pinning a floor that's clearly
        // less than today's count.
        #expect(BonjourDeviceIdentifier.appleModelLookup.count >= 80)
    }

    @Test("Every lookup-table entry has a non-empty friendly name")
    func everyLookupEntryHasFriendlyName() {
        for (identifier, entry) in BonjourDeviceIdentifier.appleModelLookup {
            #expect(!entry.friendlyName.isEmpty, "\(identifier) has empty friendly name")
        }
    }

    @Test("Every iPhone* identifier in the table maps to the phone category")
    func everyIPhoneIdentifierIsPhoneCategory() {
        // Pin the cross-cutting invariant — if someone adds a new
        // iPhone entry later and accidentally categorizes it as
        // `.tablet`, the test catches it.
        let iPhoneEntries = BonjourDeviceIdentifier.appleModelLookup.filter {
            $0.key.hasPrefix("iPhone")
        }
        for (identifier, entry) in iPhoneEntries {
            #expect(entry.category == .phone, "\(identifier) categorized as \(entry.category), expected .phone")
        }
    }

    @Test("Every AppleTV* identifier in the table maps to the tv category")
    func everyAppleTVIdentifierIsTVCategory() {
        let appleTVEntries = BonjourDeviceIdentifier.appleModelLookup.filter {
            $0.key.hasPrefix("AppleTV")
        }
        for (identifier, entry) in appleTVEntries {
            #expect(entry.category == .tv, "\(identifier) categorized as \(entry.category), expected .tv")
        }
    }
}
