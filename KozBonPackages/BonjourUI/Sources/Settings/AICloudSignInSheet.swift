//
//  AICloudSignInSheet.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICloud
import BonjourCore
import BonjourLocalization

// MARK: - AICloudSignInSheet

/// Modal sheet that lets the user paste their Anthropic API key.
///
/// Presented from `SettingsView` when the user taps "Sign in to
/// Claude" on the AI Backend row. The sheet's view model handles
/// validation (`sk-ant-` prefix check) and persists via the
/// injected credentials store. On a successful save the sheet
/// dismisses; the parent observes the credentials store and
/// re-renders the AI Backend row to show "Signed in".
struct AICloudSignInSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var viewModel: AICloudSignInViewModel
    @FocusState private var isAPIKeyFieldFocused: Bool

    /// The credentials store this sheet writes to. Held by the
    /// owning view so it persists for the parent's lifetime; the
    /// sheet's view model captures it at init.
    init(credentialsStore: any AICloudCredentialsStore) {
        _viewModel = State(initialValue: AICloudSignInViewModel(credentialsStore: credentialsStore))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(
                        String(localized: Strings.Settings.aiCloudAPIKeyPlaceholder),
                        text: Binding(
                            get: { viewModel.apiKey },
                            set: { newValue in
                                viewModel.apiKey = newValue
                                viewModel.validate(
                                    localizedInvalidKeyMessage:
                                        String(localized: Strings.Settings.aiCloudInvalidKey)
                                )
                            }
                        )
                    )
                    .textContentType(.password)
                    #if os(iOS) || os(visionOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    #endif
                    .focused($isAPIKeyFieldFocused)
                    .accessibilityLabel(String(localized: Strings.Settings.aiCloudAPIKeyFieldLabel))

                    if let message = viewModel.validationMessage {
                        Text(verbatim: message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityAddTraits(.isStaticText)
                    }
                } header: {
                    Text(Strings.Settings.aiCloudSignInTitle)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.Settings.aiCloudSignInPrompt)

                        Button {
                            if let url = URL(string: "https://console.anthropic.com/settings/keys") {
                                openURL(url)
                            }
                        } label: {
                            Label(
                                Strings.Settings.aiCloudSignInLearnMore,
                                systemImage: "arrow.up.right.square"
                            )
                            .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)

                        if let keychainError = viewModel.keychainError {
                            Text(verbatim: keychainError)
                                .foregroundStyle(.orange)
                                .accessibilityAddTraits(.isStaticText)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            #if os(macOS)
            .frame(width: 460, height: 360)
            #endif
            .navigationTitle(String(localized: Strings.Settings.aiCloudSignInTitle))
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: Strings.Buttons.cancel)) {
                        dismiss()
                    }
                    .accessibilityIdentifier("aiCloudSignIn.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: Strings.Settings.aiCloudSignInSave)) {
                        if viewModel.save() {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isSaveEnabled)
                    .accessibilityHint(
                        viewModel.isSaveEnabled
                            ? ""
                            : String(localized: Strings.Accessibility.formIncompleteHint)
                    )
                    .accessibilityIdentifier("aiCloudSignIn.save")
                }
            }
            .onAppear {
                // Auto-focus the field so users can paste their
                // key without an extra tap. iOS keyboards appear
                // immediately; on macOS the field already shows
                // its insertion cursor.
                isAPIKeyFieldFocused = true
            }
        }
    }
}
