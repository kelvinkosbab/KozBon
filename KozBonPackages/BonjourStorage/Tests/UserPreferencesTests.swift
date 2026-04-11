//
//  UserPreferencesTests.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourStorage

// MARK: - UserPreferencesTests

@Suite("UserPreferences")
@MainActor
struct UserPreferencesTests {

    // MARK: - Default Values

    @Test func defaultAiAnalysisEnabled() {
        let prefs = UserPreferences()
        #expect(prefs.aiAnalysisEnabled)
    }

    @Test func defaultAiExpertiseLevel() {
        let prefs = UserPreferences()
        #expect(prefs.aiExpertiseLevel == "beginner")
    }

    @Test func defaultSortOrder() {
        let prefs = UserPreferences()
        #expect(prefs.defaultSortOrder == "")
    }

    // MARK: - Mutation

    @Test func aiAnalysisEnabledCanBeDisabled() {
        let prefs = UserPreferences()
        prefs.aiAnalysisEnabled = false
        #expect(!prefs.aiAnalysisEnabled)
    }

    @Test func aiExpertiseLevelCanBeSetToTechnical() {
        let prefs = UserPreferences()
        prefs.aiExpertiseLevel = "technical"
        #expect(prefs.aiExpertiseLevel == "technical")
    }

    @Test func defaultSortOrderCanBeSet() {
        let prefs = UserPreferences()
        prefs.defaultSortOrder = "hostNameAsc"
        #expect(prefs.defaultSortOrder == "hostNameAsc")
    }
}
