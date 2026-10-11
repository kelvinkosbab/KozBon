//
//  SiriTipRow.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import SwiftUI
import BonjourStorage

// MARK: - SiriTips

/// Where Siri tips can show. `SiriTipView` and `ShortcutsLink` are
/// unavailable on macOS, tvOS and watchOS.
enum SiriTips {
    #if os(iOS) || os(visionOS)
    static let isSupported = true
    #else
    static let isSupported = false
    #endif
}

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
        #if os(iOS) || os(visionOS)
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
