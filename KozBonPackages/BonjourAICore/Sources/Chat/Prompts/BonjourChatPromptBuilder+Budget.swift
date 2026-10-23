//
//  BonjourChatPromptBuilder+Budget.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ContextBudget

extension BonjourChatPromptBuilder {

    /// How much network and library detail the `<context>` and
    /// `<referenced>` blocks carry.
    ///
    /// Apple's on-device model has a ~4K-token window shared by the
    /// system prompt, the context, and the answer, so ``onDevice``
    /// trims hard. Cloud models have 200K+ windows, so ``cloud``
    /// sends what a good answer needs: addresses and TXT records for
    /// every listed service, the library's type names, each
    /// service's categories, and descriptions of the types on the
    /// network.
    public struct ContextBudget: Sendable, Equatable {

        /// Discovered services rendered with addresses and TXT
        /// records. The rest of the list gets a one-line entry.
        public let richDetailServiceCap: Int

        /// Discovered services rendered at all. Anything past this
        /// is summarized as "...and N more".
        public let briefDetailServiceCap: Int

        /// Addresses rendered per rich entry.
        public let addressesPerService: Int

        /// TXT records rendered per rich entry.
        public let txtRecordsPerService: Int

        /// Whether the library section lists type names under each
        /// category, rather than only the per-category counts.
        public let listsLibraryTypeNames: Bool

        /// Whether discovered and published services carry their
        /// categories (Apple Devices, Media & Streaming, …), so
        /// "which Apple devices are on my network?" needn't be
        /// guessed from type identifiers.
        public let tagsServiceCategories: Bool

        /// Whether the context describes every service type found on
        /// the network, not just the ones the user names.
        public let describesDiscoveredTypes: Bool

        /// Service types the `<referenced>` block describes per turn.
        public let referencedTypeCap: Int

        /// Sized for the on-device model. Five rich entries at ~100
        /// tokens each leave room for the system prompt, the brief
        /// tail, the library summary, and the user message; with ten
        /// we routinely threw `exceededContextWindowSize` on
        /// service-rich networks.
        public static let onDevice = ContextBudget(
            richDetailServiceCap: 5,
            briefDetailServiceCap: 50,
            addressesPerService: 3,
            txtRecordsPerService: 6,
            listsLibraryTypeNames: false,
            tagsServiceCategories: false,
            describesDiscoveredTypes: false,
            referencedTypeCap: 5
        )

        /// Sized for cloud models. Even a busy network at these caps
        /// stays in the low tens of thousands of tokens.
        public static let cloud = ContextBudget(
            richDetailServiceCap: 100,
            briefDetailServiceCap: 200,
            addressesPerService: 8,
            txtRecordsPerService: 20,
            listsLibraryTypeNames: true,
            tagsServiceCategories: true,
            describesDiscoveredTypes: true,
            referencedTypeCap: 20
        )
    }
}
