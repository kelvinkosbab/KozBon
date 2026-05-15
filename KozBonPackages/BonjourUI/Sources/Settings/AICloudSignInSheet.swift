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
public struct AICloudSignInSheet: View {

    @Environment(\.dismiss) private var dismiss

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
    public init(credentialsStore: any AICloudCredentialsStore, provider: AICloudProvider = .anthropic) {
        self.provider = provider
        _viewModel = State(initialValue: AICloudSignInViewModel(
            credentialsStore: credentialsStore,
            provider: provider
        ))
    }

    public var body: some View {
        NavigationStack {
            Form {
                // API key entry section — the prompt copy moves
                // to the section's footer so VoiceOver reads it
                // right after the field. Previously sat in a
                // VStack with the link below it, which made the
                // input area feel cluttered.
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
                    // Thread the validation message into the
                    // field's accessibility hint so VoiceOver
                    // users hear the format error as part of
                    // the field rather than having to swipe
                    // away to find the orange-text sibling.
                    .accessibilityHint(viewModel.validationMessage ?? "")

                    if let message = viewModel.validationMessage {
                        Text(verbatim: message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityAddTraits(.isStaticText)
                    }
                } footer: {
                    Text(signInPrompt)
                }

                // "Get a key" external link as its own form row.
                // SwiftUI `Link` integrates with `openURL` and
                // gets the system tint automatically; the
                // trailing external-link glyph signals the tap
                // leaves the app — matches iOS Settings'
                // "Privacy Policy" / "Terms of Use" affordance.
                if let url = URL(string: getKeyURLString) {
                    Section {
                        Link(destination: url) {
                            HStack {
                                Text(getKeyLabel)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image.externalLink
                                    .foregroundStyle(.secondary)
                                    .imageScale(.medium)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityHint(String(localized: getKeyHint))
                    }
                }

                // Keychain save errors get their own section so
                // they're visually distinct from the input area
                // and can be announced via the `.onChange`
                // observer below without competing with the
                // section footer.
                if let keychainError = viewModel.keychainError {
                    Section {
                        Text(verbatim: keychainError)
                            .foregroundStyle(.orange)
                            .accessibilityAddTraits(.isStaticText)
                    }
                }
            }
            .formStyle(.grouped)
            #if os(macOS)
            .frame(width: 460, height: 360)
            #endif
            // Title is the provider's display name alone
            // ("Claude" / "GitHub") instead of "Sign in to
            // Claude" / "Sign in to GitHub Models" — the longer
            // form ellipsizes in inline mode on iPhone SE and
            // compact width classes. Matches iOS Mail's
            // Add-Account pattern, where the sheet title is the
            // provider ("Outlook", "Google"), not the action.
            .navigationTitle(String(localized: provider.displayName))
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            // Tint the whole sheet in the provider's brand
            // color — Cancel / Save toolbar buttons, the
            // "Get a key" Link row, and any inherited-tint
            // controls pick it up. Matches iOS's branded
            // Add-Account sheets (Apple Music = red, Mail
            // providers carry their own chrome).
            .tint(provider.accentColor)
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
            // Actively announce Keychain save failures. The
            // orange-text row below the form sits under the
            // fold; without an announcement a VoiceOver user
            // has to swipe to discover the save didn't go
            // through.
            .onChange(of: viewModel.keychainError) { _, newValue in
                if let message = newValue {
                    AccessibilityNotification.Announcement(message).post()
                }
            }
        }
    }

    // MARK: - Per-Provider Copy

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
