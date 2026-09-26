//
//  BonjourScanForServicesView+RowStyle.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourModels
import BonjourScanning

// MARK: - ServiceRowStyle

/// How much of a discovered-service row's identity its enclosing
/// section header already states.
///
/// A header repeated on every row beneath it is noise, so each style
/// moves the repeated field out of the row and promotes what's left.
enum ServiceRowStyle {

    /// No section header, or one that says nothing about the row —
    /// the full host title plus service-type subtitle.
    case standalone

    /// Inside a per-service-type section.
    case inServiceTypeSection

    /// Inside a per-host section.
    case inHostSection

    init(_ key: BonjourServiceGroup.Key) {
        switch key {
        case .serviceType: self = .inServiceTypeSection
        case .hostName: self = .inHostSection
        }
    }
}

// MARK: - AI Service Explanation Sheet Modifier

#if canImport(FoundationModels)

struct AIServiceExplanationSheetModifier: ViewModifier {
    @Binding var serviceToExplain: BonjourService?

    func body(content: Content) -> some View {
        content
            .sheet(item: $serviceToExplain) { service in
                ServiceExplanationSheet(service: service)
            }
    }
}
#endif
