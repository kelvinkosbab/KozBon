//
//  BonjourChatViewModel+Intents.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourLocalization
import BonjourModels

// MARK: - Assistant Intent Handling

extension BonjourChatViewModel {

    /// Hydrate a freshly-published broker intent into the
    /// matching local `pending*` state so a `.sheet(item:)`
    /// modifier picks it up and presents the pre-filled form.
    /// The broker is consumed immediately so a re-render with
    /// the same `pendingIntent` doesn't re-fire the sheet.
    ///
    /// Each intent case dispatches to a per-case handler so
    /// this method stays a thin switch. The handlers may bail
    /// without publishing local state when a lookup fails
    /// (e.g. the user deleted the referenced type between the
    /// tool call and this handler running) — in that case
    /// the broker is still consumed at the end so the failed
    /// intent doesn't keep re-firing.
    func handlePendingIntent(
        _ newIntent: BonjourChatIntent?,
        injectedSession: (any BonjourChatSessionProtocol)?
    ) {
        guard let newIntent else { return }
        guard let session = activeSession(injected: injectedSession) else {
            return
        }

        switch newIntent {
        case let .createCustomServiceType(name, type, _, details):
            handleCreateIntent(name: name, type: type, details: details)
        case let .broadcastService(fullType, port, domain, txtRecords):
            handleBroadcastIntent(
                fullType: fullType,
                port: port,
                domain: domain,
                txtRecords: txtRecords,
                session: session
            )
        case let .editCustomServiceType(currentFullType, suggestedName, suggestedDetails):
            handleEditIntent(
                currentFullType: currentFullType,
                suggestedName: suggestedName,
                suggestedDetails: suggestedDetails,
                session: session
            )
        case let .deleteCustomServiceType(fullType):
            handleDeleteIntent(fullType: fullType, session: session)
        case let .stopBroadcast(fullType):
            handleStopBroadcastIntent(fullType: fullType, session: session)
        }

        session.intentBroker.consume()
    }

    private func handleCreateIntent(name: String, type: String, details: String) {
        // The intent's `transport` field is captured for
        // future form expansion (UDP support); the create-
        // service-type form is currently TCP-only, so it
        // isn't surfaced here.
        pendingCreateTypeIntent = PendingCreateTypeIntent(
            name: name,
            type: type,
            details: details
        )
    }

    private func handleBroadcastIntent(
        fullType: String,
        port: Int?,
        domain: String,
        txtRecords: [TxtRecordDraft],
        session: any BonjourChatSessionProtocol
    ) {
        let library = BonjourServiceType.fetchAll()
        guard let resolvedType = library.first(where: { $0.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        let dataRecords = txtRecords.map {
            BonjourService.TxtDataRecord(key: $0.key, value: $0.value)
        }
        pendingBroadcastIntent = PendingBroadcastIntent(
            serviceType: resolvedType,
            port: port,
            domain: domain,
            dataRecords: dataRecords
        )
    }

    private func handleEditIntent(
        currentFullType: String,
        suggestedName: String?,
        suggestedDetails: String?,
        session: any BonjourChatSessionProtocol
    ) {
        let library = BonjourServiceType.fetchAll()
        guard let existing = library.first(where: { $0.fullType == currentFullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingEditServiceType = BonjourServiceType(
            name: suggestedName ?? existing.name,
            type: existing.type,
            transportLayer: existing.transportLayer,
            detail: suggestedDetails ?? existing.detail
        )
    }

    private func handleDeleteIntent(
        fullType: String,
        session: any BonjourChatSessionProtocol
    ) {
        let library = BonjourServiceType.fetchAll()
        guard let existing = library.first(where: { $0.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingDeleteCustomServiceType = existing
    }

    private func handleStopBroadcastIntent(
        fullType: String,
        session: any BonjourChatSessionProtocol
    ) {
        guard let active = services.publishManager.publishedServices
            .first(where: { $0.serviceType.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingStopBroadcastService = active
    }

    // MARK: - Destructive Confirmation Helpers

    /// Localized "Are you sure you want to delete the <name>
    /// service type?" string. Empty when the pending state is
    /// nil — the binding gating the dialog ensures it isn't
    /// read in that case.
    var deleteCustomServiceTypeQuestion: String {
        guard let target = pendingDeleteCustomServiceType else { return "" }
        return Strings.Chat.confirmDeleteServiceType(target.name)
    }

    /// Localized "Are you sure you want to stop broadcasting
    /// <service_name>?" string. The "service_name" is the
    /// user-given name of the broadcast (e.g. "Living Room
    /// Speaker"), not the raw DNS-SD type.
    var stopBroadcastQuestion: String {
        guard let active = pendingStopBroadcastService else { return "" }
        return Strings.Chat.confirmStopBroadcast(active.service.name)
    }
}
