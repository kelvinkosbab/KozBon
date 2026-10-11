//
//  ServiceCategoryAppEnumTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import BonjourModels
@testable import BonjourAppIntents

// MARK: - ServiceCategoryAppEnumTests

@Suite("ServiceCategoryAppEnum")
struct ServiceCategoryAppEnumTests {

    @Test("Every model category has exactly one case")
    func coversEveryCategory() {
        let mapped = ServiceCategoryAppEnum.allCases.map(\.category)
        #expect(Set(mapped) == Set(BonjourServiceCategory.allCases))
        #expect(mapped.count == BonjourServiceCategory.allCases.count)
    }

    @Test("Every case has a display representation")
    func everyCaseIsDisplayed() {
        for value in ServiceCategoryAppEnum.allCases {
            #expect(ServiceCategoryAppEnum.caseDisplayRepresentations[value] != nil)
        }
    }

    @Test("Every library category maps to the Siri category that maps back to it")
    func roundTrips() {
        for category in BonjourServiceCategory.allCases {
            #expect(ServiceCategoryAppEnum(category).category == category)
        }
    }
}
