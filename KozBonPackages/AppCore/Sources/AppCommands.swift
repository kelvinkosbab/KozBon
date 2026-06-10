//
//  AppCommands.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(macOS)
import SwiftUI
import BonjourLocalization

// MARK: - AppCommands

/// macOS menu-bar commands: file/edit shortcuts keyed off
/// `@FocusedBinding` / `@FocusedValue` so they enable only when
/// the relevant scene is in focus, plus a curated Help menu
/// that replaces the default "Search Help" entry.
struct AppCommands: Commands {

    @FocusedBinding(\.isBroadcastServicePresented) private var isBroadcastServicePresented
    @FocusedBinding(\.isCreateServiceTypePresented) private var isCreateServiceTypePresented
    @FocusedValue(\.refreshScan) private var refreshScan

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(Strings.Buttons.broadcastService) {
                isBroadcastServicePresented = true
            }
            .disabled(isBroadcastServicePresented == nil)
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button(Strings.Buttons.createCustomServiceType) {
                isCreateServiceTypePresented = true
            }
            .disabled(isCreateServiceTypePresented == nil)
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Divider()

            Button(Strings.Buttons.refresh) {
                refreshScan?()
            }
            .disabled(refreshScan == nil)
            .keyboardShortcut("r", modifiers: .command)
        }

        // URLs are hardcoded constants — `Link` requires a
        // non-optional `URL`, and these can't fail at runtime.
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
