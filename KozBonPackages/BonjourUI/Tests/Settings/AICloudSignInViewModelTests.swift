//
//  AICloudSignInViewModelTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourUI

// MARK: - AICloudSignInViewModelTests

@Suite("AICloudSignInViewModel")
@MainActor
struct AICloudSignInViewModelTests {

    // MARK: - Save Enablement

    @Test("`isSaveEnabled` is false when the field is empty")
    func saveDisabledForEmptyInput() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = ""
        #expect(!viewModel.isSaveEnabled)
    }

    @Test("`isSaveEnabled` is false when the field is whitespace only")
    func saveDisabledForWhitespaceOnly() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "   "
        #expect(!viewModel.isSaveEnabled)
    }

    @Test("`isSaveEnabled` is false when the prefix is wrong")
    func saveDisabledForWrongPrefix() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "sk-openai-abc123"
        #expect(!viewModel.isSaveEnabled)
    }

    @Test("`isSaveEnabled` is false when only the prefix is present")
    func saveDisabledForPrefixOnly() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "sk-ant-"
        #expect(!viewModel.isSaveEnabled)
    }

    @Test("`isSaveEnabled` is true for a plausibly-shaped Anthropic key")
    func saveEnabledForValidShape() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "sk-ant-test-key-12345"
        #expect(viewModel.isSaveEnabled)
    }

    @Test("Leading and trailing whitespace doesn't disable the Save button")
    func saveEnabledTrimsWhitespace() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "   sk-ant-test-key-12345  \n"
        #expect(viewModel.isSaveEnabled)
    }

    // MARK: - Validation

    @Test("`validate` surfaces a localized message for non-Anthropic prefixes")
    func validateSurfacesMessage() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "sk-openai-abc"
        viewModel.validate(localizedInvalidKeyMessage: "Invalid key format.")
        #expect(viewModel.validationMessage == "Invalid key format.")
    }

    @Test("`validate` clears the message when the input becomes valid")
    func validateClearsForValidInput() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "sk-openai-abc"
        viewModel.validate(localizedInvalidKeyMessage: "Invalid.")
        #expect(viewModel.validationMessage != nil)

        viewModel.apiKey = "sk-ant-valid-shape-1234"
        viewModel.validate(localizedInvalidKeyMessage: "Invalid.")
        #expect(viewModel.validationMessage == nil)
    }

    @Test("`validate` clears the message when the input becomes empty")
    func validateClearsForEmptyInput() {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "sk-openai-abc"
        viewModel.validate(localizedInvalidKeyMessage: "Invalid.")
        #expect(viewModel.validationMessage != nil)

        viewModel.apiKey = ""
        viewModel.validate(localizedInvalidKeyMessage: "Invalid.")
        #expect(viewModel.validationMessage == nil)
    }

    // MARK: - Save

    @Test("`save` persists the trimmed key and clears the field")
    func saveTrimsAndPersists() throws {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = "  sk-ant-fresh-key-99  \n"

        let succeeded = viewModel.save()

        #expect(succeeded)
        #expect(try store.apiKey(for: .anthropic) == "sk-ant-fresh-key-99")
        #expect(viewModel.apiKey.isEmpty, "field should clear after successful save")
        #expect(viewModel.keychainError == nil)
    }

    @Test("`save` returns false and doesn't persist when the field is empty")
    func saveBailsOnEmptyField() throws {
        let store = InMemoryAICloudCredentialsStore()
        let viewModel = AICloudSignInViewModel(credentialsStore: store)
        viewModel.apiKey = ""

        let succeeded = viewModel.save()

        #expect(!succeeded)
        #expect(try store.apiKey(for: .anthropic) == nil)
    }
}
