//
//  AICloudSignInSheet.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICore
import BonjourCore
import BonjourLocalization

// MARK: - AICloudSignInSheet

/// Modal sheet that lets the user paste a cloud-provider API key.
///
/// Presented from `SettingsView` (and from `BonjourChatView`'s
/// in-tab prompt) when the user taps a sign-in row. The sheet's
/// view model handles per-provider format validation
/// (`sk-ant-` for Anthropic, `ghp_` / `github_pat_` / `gho_` for
/// GitHub) and persists via the injected credentials store. On a
/// successful save the sheet dismisses; the parent observes the
/// credentials store and re-renders the row to show "Signed in".
///
/// Provider-specific copy and the external "get a key" URL come
/// from per-provider helpers below — the view body stays
/// provider-agnostic.
struct AICloudSignInSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var viewModel: AICloudSignInViewModel
    @FocusState private var isAPIKeyFieldFocused: Bool

    /// The provider this sheet is signing in to. Captured at
    /// init so the per-provider copy and URLs stay stable for
    /// the lifetime of the sheet (a mid-sheet backend swap in
    /// Settings would never happen — the user has to commit /
    /// cancel first).
    private let provider: AICloudProvider

    /// The credentials store this sheet writes to. Held by the
    /// owning view so it persists for the parent's lifetime; the
    /// sheet's view model captures it at init.
    init(credentialsStore: any AICloudCredentialsStore, provider: AICloudProvider = .anthropic) {
        self.provider = provider
        _viewModel = State(initialValue: AICloudSignInViewModel(
            credentialsStore: credentialsStore,
            provider: provider
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(
                        String(localized: apiKeyPlaceholder),
                        text: Binding(
                            get: { viewModel.apiKey },
                            set: { newValue in
                                viewModel.apiKey = newValue
                                viewModel.validate(
                                    localizedInvalidKeyMessage: String(localized: invalidKeyMessage)
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
                    .accessibilityLabel(String(localized: apiKeyFieldLabel))

                    if let message = viewModel.validationMessage {
                        Text(verbatim: message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityAddTraits(.isStaticText)
                    }
                } header: {
                    Text(signInTitle)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(signInPrompt)

                        Button {
                            if let url = URL(string: getKeyURLString) {
                                openURL(url)
                            }
                        } label: {
                            Label {
                                Text(getKeyLabel)
                            } icon: {
                                Image.externalLink
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                        .accessibilityHint(String(localized: getKeyHint))

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
            .navigationTitle(String(localized: signInTitle))
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

    // MARK: - Per-Provider Copy

    private var signInTitle: LocalizedStringResource {
        switch provider {
        case .anthropic: return Strings.Settings.aiCloudSignInTitle
        case .github:    return Strings.Settings.aiCloudSignInTitleGitHub
        }
    }

    private var signInPrompt: LocalizedStringResource {
        switch provider {
        case .anthropic: return Strings.Settings.aiCloudSignInPrompt
        case .github:    return Strings.Settings.aiCloudSignInPromptGitHub
        }
    }

    private var apiKeyPlaceholder: LocalizedStringResource {
        switch provider {
        case .anthropic: return Strings.Settings.aiCloudAPIKeyPlaceholder
        case .github:    return Strings.Settings.aiCloudAPIKeyPlaceholderGitHub
        }
    }

    private var apiKeyFieldLabel: LocalizedStringResource {
        switch provider {
        case .anthropic: return Strings.Settings.aiCloudAPIKeyFieldLabel
        case .github:    return Strings.Settings.aiCloudAPIKeyFieldLabelGitHub
        }
    }

    private var invalidKeyMessage: LocalizedStringResource {
        switch provider {
        case .anthropic: return Strings.Settings.aiCloudInvalidKey
        case .github:    return Strings.Settings.aiCloudInvalidKeyGitHub
        }
    }

    private var getKeyLabel: LocalizedStringResource {
        switch provider {
        case .anthropic: return Strings.Settings.aiCloudSignInLearnMore
        case .github:    return Strings.Settings.aiCloudSignInLearnMoreGitHub
        }
    }

    private var getKeyHint: LocalizedStringResource {
        switch provider {
        case .anthropic: return Strings.Accessibility.aiCloudSignInLearnMoreHint
        case .github:    return Strings.Accessibility.chatOpenGitHubPATHint
        }
    }

    private var getKeyURLString: String {
        switch provider {
        case .anthropic: return "https://console.anthropic.com/settings/keys"
        case .github:    return "https://github.com/settings/tokens"
        }
    }
}
