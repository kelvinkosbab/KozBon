//
//  ChatSiriIntentDetector.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ChatSiriIntentDetector

/// Decides whether a chat message asks about using KozBon with Siri
/// or the Shortcuts app, so the prompt builder can inject the real
/// action list instead of letting the model guess at phrases.
///
/// "Siri" is a brand name written the same way in every supported
/// locale, so it carries most of the matching; the per-language
/// words for "shortcut" cover questions that never say "Siri".
public enum ChatSiriIntentDetector {

    /// Whether `message` asks about Siri or Shortcuts.
    public static func wantsSiriHelp(message: String) -> Bool {
        let lowered = message.lowercased()
        guard !lowered.isEmpty else { return false }
        return matchPhrases.contains { lowered.contains($0) }
    }

    static let matchPhrases: [String] = [
        "siri",
        "shortcut",         // en
        "atajo",            // es
        "raccourci",        // fr
        "kurzbefehl",       // de
        "ショートカット",      // ja
        "快捷指令",           // zh-Hans
        "اختصار",           // ar
        "الاختصارات",        // ar (plural)
        "קיצור"             // he
    ]
}
