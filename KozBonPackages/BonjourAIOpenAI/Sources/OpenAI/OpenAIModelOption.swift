//
//  OpenAIModelOption.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - OpenAIModelOption

/// One selectable OpenAI model in the Settings picker.
///
/// A struct rather than an enum for the same reason
/// ``GeminiModelOption`` is: OpenAI ships new models between KozBon
/// releases, and a hardcoded enum leaves users pinned to whatever
/// generation shipped with the binary.
///
/// Options come from two places — the live catalog
/// (``OpenAIModelCatalog``, `GET /v1/models` with the user's own
/// key) and ``OpenAIModel``, the small compiled-in list used as the
/// offline floor. ``isBuiltIn`` records which.
public struct OpenAIModelOption: Identifiable, Hashable, Sendable {

    /// The API model identifier. Also the value persisted in
    /// preferences.
    public let id: String

    /// Human-readable name for the picker row.
    public let displayName: String

    /// Whether this came from the compiled-in fallback rather than
    /// the live catalog.
    public let isBuiltIn: Bool

    public init(id: String, displayName: String, isBuiltIn: Bool) {
        self.id = id
        self.displayName = displayName
        self.isBuiltIn = isBuiltIn
    }

    /// Builds an option from a compiled-in fallback case.
    public init(builtIn model: OpenAIModel) {
        self.init(id: model.rawValue, displayName: model.displayName, isBuiltIn: true)
    }

    /// The offline fallback list, most-capable-first to match the
    /// catalog's ordering convention.
    public static var builtInOptions: [OpenAIModelOption] {
        OpenAIModel.allCases.map(OpenAIModelOption.init(builtIn:))
    }

    // MARK: - Display Names

    /// Derives a picker label from a model identifier.
    ///
    /// Unlike Anthropic and Google, OpenAI's `/v1/models` returns no
    /// display name, so one is built here: `gpt-5.4-mini` becomes
    /// "GPT-5.4 Mini". Identifiers outside the `gpt-` family
    /// (`o4-mini`) are already how OpenAI writes them and pass
    /// through unchanged.
    public static func displayName(forIdentifier identifier: String) -> String {
        let parts = identifier.split(separator: "-").map(String.init)
        guard parts.count >= 2, parts[0].lowercased() == "gpt" else {
            return identifier
        }
        let suffix = parts.dropFirst(2).map { word in
            word.prefix(1).uppercased() + word.dropFirst()
        }
        return (["GPT-\(parts[1])"] + suffix).joined(separator: " ")
    }
}
