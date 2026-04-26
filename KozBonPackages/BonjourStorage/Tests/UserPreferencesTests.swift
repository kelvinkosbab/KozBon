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

    @Test("New `UserPreferences` instance has `aiAnalysisEnabled` true")
    func defaultAiAnalysisEnabled() {
        let prefs = UserPreferences()
        #expect(prefs.aiAnalysisEnabled)
    }

    @Test("New `UserPreferences` instance has `aiExpertiseLevel` set to `\"basic\"`")
    func defaultAiExpertiseLevel() {
        let prefs = UserPreferences()
        #expect(prefs.aiExpertiseLevel == "basic")
    }

    @Test("New `UserPreferences` instance has `defaultSortOrder` as the empty string")
    func defaultSortOrder() {
        let prefs = UserPreferences()
        #expect(prefs.defaultSortOrder == "")
    }

    // MARK: - Mutation

    @Test("`aiAnalysisEnabled` accepts a write to false and reads it back")
    func aiAnalysisEnabledCanBeDisabled() {
        let prefs = UserPreferences()
        prefs.aiAnalysisEnabled = false
        #expect(!prefs.aiAnalysisEnabled)
    }

    @Test("`aiExpertiseLevel` accepts a write to `\"technical\"` and reads it back")
    func aiExpertiseLevelCanBeSetToTechnical() {
        let prefs = UserPreferences()
        prefs.aiExpertiseLevel = "technical"
        #expect(prefs.aiExpertiseLevel == "technical")
    }

    @Test("`defaultSortOrder` accepts a write to a non-empty value and reads it back")
    func defaultSortOrderCanBeSet() {
        let prefs = UserPreferences()
        prefs.defaultSortOrder = "hostNameAsc"
        #expect(prefs.defaultSortOrder == "hostNameAsc")
    }

    // MARK: - Static Defaults

    @Test("Static `defaultAIAnalysisEnabled` is true so AI analysis is opt-out")
    func staticDefaultAIAnalysisEnabledIsTrue() {
        #expect(UserPreferences.defaultAIAnalysisEnabled)
    }

    @Test("Static `defaultAIExpertiseLevel` is `\"basic\"` for newcomer-friendly output")
    func staticDefaultAIExpertiseLevelIsBasic() {
        #expect(UserPreferences.defaultAIExpertiseLevel == "basic")
    }

    @Test("Static `defaultSortOrder` is empty so the UI falls back to its built-in default")
    func staticDefaultSortOrderIsEmpty() {
        #expect(UserPreferences.defaultSortOrder == "")
    }

    @Test("Static `defaultAIResponseLength` is `\"standard\"` for medium-length AI replies")
    func staticDefaultAIResponseLengthIsStandard() {
        #expect(UserPreferences.defaultAIResponseLength == "standard")
    }

    @Test("Instance defaults match `UserPreferences.default*` constants exactly")
    func instanceDefaultsMatchStaticDefaults() {
        let prefs = UserPreferences()
        #expect(prefs.aiAnalysisEnabled == UserPreferences.defaultAIAnalysisEnabled)
        #expect(prefs.aiExpertiseLevel == UserPreferences.defaultAIExpertiseLevel)
        #expect(prefs.aiResponseLength == UserPreferences.defaultAIResponseLength)
        #expect(prefs.defaultSortOrder == UserPreferences.defaultSortOrder)
    }

    // MARK: - Response Length

    @Test("`aiResponseLength` accepts a write to `\"brief\"` and reads it back")
    func aiResponseLengthCanBeSetToBrief() {
        let prefs = UserPreferences()
        prefs.aiResponseLength = "brief"
        #expect(prefs.aiResponseLength == "brief")
    }

    @Test("`aiResponseLength` accepts a write to `\"thorough\"` and reads it back")
    func aiResponseLengthCanBeSetToThorough() {
        let prefs = UserPreferences()
        prefs.aiResponseLength = "thorough"
        #expect(prefs.aiResponseLength == "thorough")
    }

    // MARK: - Persist Chat History

    @Test("New `UserPreferences` has `persistChatHistory` false (opt-in feature)")
    func defaultPersistChatHistoryIsFalse() {
        let prefs = UserPreferences()
        #expect(!prefs.persistChatHistory)
    }

    @Test("New `UserPreferences` has `chatHistory` nil (no saved blob)")
    func defaultChatHistoryIsNil() {
        let prefs = UserPreferences()
        #expect(prefs.chatHistory == nil)
    }

    @Test("Static `defaultPersistChatHistory` is false to preserve the original fresh-slate behavior")
    func staticDefaultPersistChatHistoryIsFalse() {
        #expect(!UserPreferences.defaultPersistChatHistory)
    }

    @Test("`persistChatHistory` accepts a write to true and reads it back")
    func persistChatHistoryCanBeEnabled() {
        let prefs = UserPreferences()
        prefs.persistChatHistory = true
        #expect(prefs.persistChatHistory)
    }

    @Test("`chatHistory` accepts a write to a non-nil blob and reads it back")
    func chatHistoryCanBeSet() {
        let prefs = UserPreferences()
        let blob = Data("{\"messages\":[]}".utf8)
        prefs.chatHistory = blob
        #expect(prefs.chatHistory == blob)
    }
}
