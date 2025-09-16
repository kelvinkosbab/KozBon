//
//  BonjourServiceSortType.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/8/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceSortType

/// A sort option describing how Bonjour services should be ordered in lists.
///
/// This enum centralizes all supported sort behaviors used by the UI when
/// presenting discovered services. By collecting the options in one place,
/// views and view models can iterate over the full set of choices and
/// present consistent labels and behaviors across the app.
///
/// The cases cover ascending and descending ordering by either the host name
/// (service instance name) or by the service type's display name. This type
/// conforms to Identifiable for easy use in SwiftUI Lists and Menus, and
/// CaseIterable to enumerate all available sort options. You can persist the
/// selected value using its `id`, or display a localized title via
/// `hostOrServiceTitle`.
enum BonjourServiceSortType: Identifiable, CaseIterable {

    /// Sort by host name in ascending (A → Z) order.
    ///
    /// Use this option when you want service instances to be listed in a
    /// predictable, alphabetical order based on their advertised names. This is
    /// often the most familiar ordering for users scanning a list.
    ///
    /// In this project, the “host name” corresponds to the Bonjour service’s
    /// instance name (e.g., the value surfaced as `service.name`). Selecting
    /// this option will place names earlier in the alphabet nearer the top.
    case hostNameAsc

    /// Sort by host name in descending (Z → A) order.
    ///
    /// Choose this option when you want to reverse the typical alphabetical
    /// ordering of service instance names. This can be useful when recent or
    /// higher-sorted names naturally fall later in the alphabet and should be
    /// surfaced first.
    ///
    /// As with the ascending variant, the “host name” is the Bonjour service’s
    /// instance name. Selecting this option will place names later in the
    /// alphabet nearer the top.
    case hostNameDesc

    /// Sort by service type name in ascending (A → Z) order.
    ///
    /// This option groups and orders services by their human-readable service
    /// type name, making it easier to compare devices or apps that share the
    /// same underlying protocol. It is helpful when the type is more relevant
    /// than the instance name.
    ///
    /// The “service type name” here corresponds to the display name associated
    /// with a Bonjour service type (for example, “AirPlay” or “SSH”). Selecting
    /// this option will place type names earlier in the alphabet nearer the top.
    case serviceNameAsc

    /// Sort by service type name in descending (Z → A) order.
    ///
    /// Choose this option to reverse the alphabetical ordering of service type
    /// names. This can be useful when you want certain types that sort later in
    /// the alphabet to appear first for quick access.
    ///
    /// As with the ascending variant, the “service type name” corresponds to
    /// the user-facing label for the Bonjour service type. Selecting this option
    /// will place type names later in the alphabet nearer the top.
    case serviceNameDesc

    /// A stable identifier for the sort option, useful for SwiftUI's Identifiable conformance.
    ///
    /// The returned string is stable and can be used for persistence (e.g.,
    /// storing a selected sort type in UserDefaults) or for diffing in SwiftUI
    /// lists. This avoids relying on enum ordinal values, which are not stable.
    ///
    /// When you need to recreate a sort option from persisted state, you can
    /// compare the stored identifier to the `id` of each `allCases` element.
    var id: String {
        switch self {
        case .hostNameAsc:
            "hostNameAsc"

        case .hostNameDesc:
            "hostNameDesc"

        case .serviceNameAsc:
            "serviceNameAsc"

        case .serviceNameDesc:
            "serviceNameDesc"
        }
    }

    /// A localized, user-facing title describing the sort option, suitable for menus and section headers.
    ///
    /// These strings are intended for direct presentation in the UI, such as in
    /// a sort menu or in section headers that reflect the current sort mode.
    /// They are localized using `NSLocalizedString` to support internationalization.
    ///
    /// If you introduce new sort cases, add corresponding localized strings so
    /// the UI remains consistent across languages. The comments supplied here
    /// help translators understand the usage context.
    var hostOrServiceTitle: String {
        switch self {
        case .hostNameAsc:
            NSLocalizedString(
                "By host name ascending",
                comment: "By host name ascending section title"
            )

        case .hostNameDesc:
            NSLocalizedString(
                "By host name descending",
                comment: "By host name descending section title"
            )

        case .serviceNameAsc:
            NSLocalizedString(
                "By service type ascending",
                comment: "By service type ascending section title"
            )

        case .serviceNameDesc:
            NSLocalizedString(
                "By service type descending",
                comment: "By service type descending section title"
            )
        }
    }
}
