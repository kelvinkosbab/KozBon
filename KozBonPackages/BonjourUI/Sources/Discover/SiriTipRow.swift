//
//  SiriTipRow.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import SwiftUI
import BonjourStorage

// MARK: - SiriTipRow

/// A list row suggesting the Siri phrase for `intent`.
///
/// Callers show it only while `siriTipsEnabled` is on. Closing any
/// tip turns that preference off, which hides every tip; Settings
/// turns them back on.
struct SiriTipRow<Intent: AppIntent>: View {

    @Environment(\.preferencesStore) private var preferencesStore

    let intent: Intent

    var body: some View {
        #if !os(tvOS) && !os(watchOS)
        SiriTipView(intent: intent, isVisible: isVisible)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        #endif
    }

    private var isVisible: Binding<Bool> {
        Binding {
            preferencesStore.siriTipsEnabled
        } set: { newValue in
            preferencesStore.siriTipsEnabled = newValue
        }
    }
}
