//
//  AppCommands.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(macOS)
import SwiftUI
import BonjourLocalization

// MARK: - AppCommands

/// macOS menu-bar commands for the KozBon app: file/edit shortcuts
/// keyed off `@FocusedBinding`/`@FocusedValue` so they enable only
/// when the relevant scene is in focus, plus a curated Help menu
/// that replaces the default "Search Help" entry.
///
/// Lives in its own file so `AppCore.swift` stays focused on the
/// `@main App` skeleton — scene composition, environment plumbing,
/// the chat session prewarm. The `force_unwrapping` SwiftLint
/// disable scoped to the Help-menu URLs is contained to this file
/// rather than mingling with the app entry point.
struct AppCommands: Commands {

    @FocusedBinding(\.isBroadcastServicePresented) private var isBroadcastServicePresented
    @FocusedBinding(\.isCreateServiceTypePresented) private var isCreateServiceTypePresented
    @FocusedValue(\.refreshScan) private var refreshScan

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(String(localized: Strings.Buttons.broadcastService)) {
                isBroadcastServicePresented = true
            }
            .disabled(isBroadcastServicePresented == nil)
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button(String(localized: Strings.Buttons.createCustomServiceType)) {
                isCreateServiceTypePresented = true
            }
            .disabled(isCreateServiceTypePresented == nil)
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Divider()

            Button(String(localized: Strings.Buttons.refresh)) {
                refreshScan?()
            }
            .disabled(refreshScan == nil)
            .keyboardShortcut("r", modifiers: .command)
        }

        // Replace the system Help menu (which only ever offered "Search"
        // by default) with curated links the user can reach for when
        // KozBon shows them something they don't recognize. Items are
        // grouped: app-level resources (source, vendor narrative, the
        // human-readable IANA registry, Apple's port reference) above
        // the divider; protocol specs below. The links open in the
        // user's default browser via `Link`, which renders as a regular
        // menu item on macOS.
        //
        // The URLs are hardcoded constants known to be valid — the
        // force-unwraps can't fail at runtime, and `Link`'s API requires
        // a non-optional `URL`. The disables are scoped to this block.
        // swiftlint:disable force_unwrapping
        CommandGroup(replacing: .help) {
            Link(
                String(localized: Strings.Help.kozbonOnGitHub),
                destination: URL(string: "https://github.com/kelvinkosbab/KozBon")!
            )

            Divider()

            Link(
                String(localized: Strings.Help.aboutBonjour),
                destination: URL(string: "https://developer.apple.com/bonjour/")!
            )
            Link(
                String(localized: Strings.Help.ianaServiceRegistry),
                destination: URL(string: "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml")!
            )
            Link(
                String(localized: Strings.Help.applePortsReference),
                destination: URL(string: "https://support.apple.com/HT202944")!
            )

            Divider()

            Link(
                String(localized: Strings.Help.mdnsSpecification),
                destination: URL(string: "https://datatracker.ietf.org/doc/html/rfc6762")!
            )
            Link(
                String(localized: Strings.Help.dnssdSpecification),
                destination: URL(string: "https://datatracker.ietf.org/doc/html/rfc6763")!
            )
        }
        // swiftlint:enable force_unwrapping
    }
}
#endif
