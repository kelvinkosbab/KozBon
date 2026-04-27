//
//  BonjourDeviceIdentifierTests.swift
//  BonjourModels
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourModels

// swiftlint:disable file_length type_body_length
// One coherent suite covering every strategy in
// `BonjourDeviceIdentifier`. Splitting it across files would force
// readers to hop between test files to understand the priority
// chain, which is exactly the property these tests pin. Same
// precedent as the source file's own table-driven length disable.

// MARK: - BonjourDeviceIdentifierTests

/// Pin the deterministic device-identification surface. Covers Apple
/// devices plus the most common non-Apple hardware we can recognize
/// from public TXT-record schemas, hostname conventions, and DNS-SD
/// service-type signals. Every strategy here is a candidate for
/// fallback when the AI Insights path can't reliably identify a
/// device, so regressions need to fail loudly.
@Suite("BonjourDeviceIdentifier")
struct BonjourDeviceIdentifierTests {

    // MARK: - Helpers

    private func txt(_ pairs: [String: String]) -> [BonjourService.TxtDataRecord] {
        pairs.map { BonjourService.TxtDataRecord(key: $0.key, value: $0.value) }
    }

    private func identify(
        txt records: [BonjourService.TxtDataRecord] = [],
        hostname: String = "",
        serviceName: String = "",
        serviceType: String? = nil
    ) -> DeviceIdentification? {
        BonjourDeviceIdentifier.identify(
            txtRecords: records,
            hostname: hostname,
            serviceName: serviceName,
            serviceType: serviceType
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

    @Test("Hostname `sonos-living-room.local.` resolves to Sonos speaker (medium confidence)")
    func sonosHostnameResolves() {
        let result = identify(hostname: "sonos-living-room.local.")
        #expect(result?.friendlyName == "Sonos speaker")
        #expect(result?.category == .speaker)
        #expect(result?.confidence == .medium)
    }

    @Test("Truly unrecognizable hostname produces nil — the identifier doesn't make things up")
    func unknownHostnameStillReturnsNil() {
        // No Apple keyword, no vendor keyword, no service type to
        // fall back on. The identifier must return nil rather than
        // guess at a category.
        let result = identify(hostname: "zxw1234.local.")
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

    // MARK: - Vendor TXT Extraction (Non-Apple)

    @Test("Chromecast `_googlecast._tcp` with `md=Chromecast Ultra` resolves to the model name (high confidence)")
    func chromecastModelTxtResolves() {
        let result = identify(
            txt: txt(["md": "Chromecast Ultra"]),
            serviceType: "_googlecast._tcp"
        )
        #expect(result?.friendlyName == "Chromecast Ultra")
        #expect(result?.category == .streamingDevice)
        #expect(result?.confidence == .high)
    }

    @Test("Chromecast `md=` outside `_googlecast._tcp` does NOT trigger the streaming-device heuristic")
    func chromecastModelTxtScopedToServiceType() {
        // The same `md=` key shows up on HomeKit accessories and
        // others — the strategy must require the googlecast service
        // type to avoid misclassifying unrelated services.
        let result = identify(
            txt: txt(["md": "Chromecast Ultra"]),
            serviceType: "_hap._tcp"
        )
        #expect(result == nil)
    }

    @Test("Printer `_ipp._tcp` with `ty=HP LaserJet Pro M404n` resolves to the model name (high confidence)")
    func printerTyTxtResolves() {
        let result = identify(
            txt: txt(["ty": "HP LaserJet Pro M404n"]),
            serviceType: "_ipp._tcp"
        )
        #expect(result?.friendlyName == "HP LaserJet Pro M404n")
        #expect(result?.category == .printer)
        #expect(result?.confidence == .high)
    }

    @Test("Printer `usb_MFG=HP` + `usb_MDL=LaserJet 4050` resolves to the combined manufacturer/model name")
    func printerUsbMfgMdlTxtResolves() {
        let result = identify(
            txt: txt(["usb_MFG": "HP", "usb_MDL": "LaserJet 4050"]),
            serviceType: "_pdl-datastream._tcp"
        )
        #expect(result?.friendlyName == "HP LaserJet 4050")
        #expect(result?.category == .printer)
        #expect(result?.confidence == .high)
    }

    @Test("Printer `usb_MDL` already prefixed with the manufacturer is not duplicated")
    func printerUsbMdlAlreadyPrefixedNotDuplicated() {
        // Some printers ship the manufacturer name embedded in
        // `usb_MDL` already. Combining naively would render
        // "HP HP LaserJet 4050" — the strategy must detect and
        // strip the duplicate prefix.
        let result = identify(
            txt: txt(["usb_MFG": "HP", "usb_MDL": "HP LaserJet 4050"]),
            serviceType: "_ipp._tcp"
        )
        #expect(result?.friendlyName == "HP LaserJet 4050")
    }

    @Test("Vendor TXT extraction is gated on the service type — `ty=` outside printer types does not match")
    func tyKeyScopedToPrinterServiceTypes() {
        // `ty` is a generic short-form key used by some HomeKit
        // accessories. The strategy must require a printer service
        // type so we don't render a HomeKit accessory's `ty` value
        // in the printer category.
        let result = identify(
            txt: txt(["ty": "Eve Energy"]),
            serviceType: "_hap._tcp"
        )
        #expect(result == nil)
    }

    // MARK: - Vendor Hostname Patterns (Non-Apple)

    @Test("Hostname `Living-Room-Roku.local.` matches Roku in the streaming-device category")
    func rokuHostnameMatches() {
        let result = identify(hostname: "Living-Room-Roku.local.")
        #expect(result?.friendlyName == "Roku")
        #expect(result?.category == .streamingDevice)
    }

    @Test("Hostname `chromecast-ultra-1234.local.` matches Chromecast Ultra before generic Chromecast")
    func chromecastUltraHostnameMatchesBeforeChromecast() {
        let result = identify(hostname: "chromecast-ultra-1234.local.")
        #expect(result?.friendlyName == "Chromecast Ultra")
    }

    @Test("Hostname `synology-nas.local.` matches Synology NAS")
    func synologyHostnameMatches() {
        let result = identify(hostname: "synology-nas.local.")
        #expect(result?.friendlyName == "Synology NAS")
        #expect(result?.category == .nas)
    }

    @Test("Hostname `Philips-Hue-Bridge.local.` matches Philips Hue Bridge")
    func philipsHueHostnameMatches() {
        let result = identify(hostname: "Philips-Hue-Bridge.local.")
        #expect(result?.friendlyName == "Philips Hue Bridge")
        #expect(result?.category == .light)
    }

    @Test("Hostname `Xbox-Series-X.local.` matches Xbox in the game-console category")
    func xboxHostnameMatches() {
        let result = identify(hostname: "Xbox-Series-X.local.")
        #expect(result?.friendlyName == "Xbox")
        #expect(result?.category == .gameConsole)
    }

    @Test("Hostname `eero-pro.local.` matches eero router")
    func eeroHostnameMatches() {
        let result = identify(hostname: "eero-pro.local.")
        #expect(result?.friendlyName == "eero router")
    }

    // MARK: - Service-Type Fallback

    @Test("`_ipp._tcp` with no other signal falls back to a generic Printer (low confidence)")
    func ippServiceTypeFallback() {
        let result = identify(serviceType: "_ipp._tcp")
        #expect(result?.friendlyName == "Printer")
        #expect(result?.category == .printer)
        #expect(result?.confidence == .low)
    }

    @Test("`_googlecast._tcp` with no TXT data falls back to a generic Google Cast device (low confidence)")
    func googleCastServiceTypeFallback() {
        let result = identify(serviceType: "_googlecast._tcp")
        #expect(result?.friendlyName == "Google Cast device")
        #expect(result?.category == .streamingDevice)
        #expect(result?.confidence == .low)
    }

    @Test("`_amzn-wplay._tcp` falls back to Fire TV (low confidence)")
    func fireTVServiceTypeFallback() {
        let result = identify(serviceType: "_amzn-wplay._tcp")
        #expect(result?.friendlyName == "Fire TV")
        #expect(result?.category == .streamingDevice)
    }

    @Test("`_sonos._tcp` falls back to a generic Sonos speaker (low confidence)")
    func sonosServiceTypeFallback() {
        let result = identify(serviceType: "_sonos._tcp")
        #expect(result?.friendlyName == "Sonos speaker")
        #expect(result?.category == .speaker)
    }

    @Test("Unknown service type produces nil — the fallback only fires for known device classes")
    func unknownServiceTypeReturnsNil() {
        let result = identify(serviceType: "_some-novel-service._tcp")
        #expect(result == nil)
    }

    // MARK: - Strategy Priority (Cross-Strategy)

    @Test("Vendor TXT (high) wins over service-type fallback (low) for the same Cast device")
    func vendorTxtBeatsServiceTypeFallback() {
        // A real Chromecast advertises `md=` AND its service type is
        // `_googlecast._tcp`. The TXT extraction returns the specific
        // model, the fallback returns "Google Cast device" — the
        // specific name must win.
        let result = identify(
            txt: txt(["md": "Chromecast Ultra"]),
            serviceType: "_googlecast._tcp"
        )
        #expect(result?.friendlyName == "Chromecast Ultra")
        #expect(result?.confidence == .high)
    }

    @Test("Hostname pattern (medium) wins over service-type fallback (low) for the same Roku")
    func hostnamePatternBeatsServiceTypeFallback() {
        // The hostname pattern says "Roku" with medium confidence;
        // the service-type fallback also says "Roku" but with low
        // confidence. The medium-confidence answer wins.
        let result = identify(
            hostname: "Living-Room-Roku.local.",
            serviceType: "_roku-rcp._tcp"
        )
        #expect(result?.confidence == .medium)
    }

    // MARK: - New Category Icons

    @Test("New non-Apple categories all have non-empty SF Symbol icon names")
    func nonAppleCategoryIconsArePopulated() {
        #expect(!DeviceIdentification.Category.printer.iconName.isEmpty)
        #expect(!DeviceIdentification.Category.streamingDevice.iconName.isEmpty)
        #expect(!DeviceIdentification.Category.nas.iconName.isEmpty)
        #expect(!DeviceIdentification.Category.light.iconName.isEmpty)
        #expect(!DeviceIdentification.Category.gameConsole.iconName.isEmpty)
    }

    @Test("Non-Apple category icons map to recognizable SF Symbols")
    func nonAppleCategoryIconAssignmentsAreSensible() {
        #expect(DeviceIdentification.Category.printer.iconName == "printer.fill")
        #expect(DeviceIdentification.Category.streamingDevice.iconName == "tv.and.mediabox.fill")
        #expect(DeviceIdentification.Category.light.iconName == "lightbulb.fill")
        #expect(DeviceIdentification.Category.gameConsole.iconName == "gamecontroller.fill")
    }
}
