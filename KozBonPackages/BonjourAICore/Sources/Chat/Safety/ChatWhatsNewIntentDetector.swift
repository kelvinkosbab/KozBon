//
//  ChatWhatsNewIntentDetector.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ChatWhatsNewIntentDetector

/// Heuristic detector that decides whether a chat message is
/// asking about what changed in recent KozBon releases.
///
/// When it matches, the prompt builder injects the real
/// ``ReleaseNotes/all`` table into a `<whats_new>` block so the
/// assistant answers from actual version history rather than
/// hallucinating release notes — the model has no training-time
/// knowledge of KozBon's changelog. When it doesn't match, the
/// release-notes block is omitted entirely, keeping the on-device
/// model's ~4K-token context window free for the network-state
/// data that most chat turns are actually about.
///
/// Mirrors ``ChatScanIntentDetector``'s structure: a single linear
/// substring scan over a concatenated set of per-language phrase
/// lists. The matcher is deliberately lenient — a false positive
/// (injecting release notes when the user meant something else)
/// costs a few hundred tokens of unused context; a false negative
/// (skipping them when the user asked "what's new?") costs a
/// *wrong answer*, which is the worse failure. So the phrase lists
/// bias toward over-matching.
///
/// Localized for all eight languages KozBon ships in: English,
/// Spanish, French, German, Japanese, Simplified Chinese, plus
/// Arabic and Hebrew. The Arabic / Hebrew coverage (which the
/// other chat detectors omit) matters here specifically because
/// the "What's new in this version?" empty-state suggestion button
/// ships in all eight locales — tapping it sends the localized
/// phrase, which has to match so the release-notes block actually
/// gets injected. Phrases from every language are checked against
/// every input, so a user typing English on a localized device
/// still gets the release-notes path.
public enum ChatWhatsNewIntentDetector {

    // MARK: - Public API

    /// Returns `true` when the user's message looks like a question
    /// about recent app updates / release notes / what's new.
    ///
    /// - Parameter message: The user's trimmed input text. The
    ///   matcher lowercases internally; callers don't need to.
    /// - Returns: Whether the chat surface should inject the
    ///   release-notes block into the assistant's context.
    public static func wantsWhatsNew(message: String) -> Bool {
        let lowered = message.lowercased()
        guard !lowered.isEmpty else { return false }
        for phrase in matchPhrases where lowered.contains(phrase) {
            return true
        }
        return false
    }

    // MARK: - Phrase Lists

    /// All localized phrase lists concatenated into a single array
    /// so ``wantsWhatsNew(message:)`` does one linear scan per
    /// invocation.
    static let matchPhrases: [String] =
        englishPhrases
        + spanishPhrases
        + frenchPhrases
        + germanPhrases
        + japanesePhrases
        + simplifiedChinesePhrases
        + arabicPhrases
        + hebrewPhrases

    /// English phrases — "what's new" question stems, changelog /
    /// release-notes vocabulary, and version-update phrasings.
    static let englishPhrases: [String] = [
        "what's new",
        "whats new",
        "what is new",
        "what's changed",
        "what changed",
        "what has changed",
        "release notes",
        "changelog",
        "change log",
        "new features",
        "new in this version",
        "new in the latest",
        "latest version",
        "latest update",
        "latest release",
        "recent updates",
        "recent changes",
        "recent versions",
        "recent releases",
        "version history",
        "update notes",
        "what's been added",
        "what was added",
        "what's improved"
    ]

    /// Spanish phrases.
    static let spanishPhrases: [String] = [
        "qué hay de nuevo",
        "que hay de nuevo",
        "novedades",
        "notas de la versión",
        "notas de version",
        "registro de cambios",
        "qué cambió",
        "que cambio",
        "nuevas funciones",
        "nuevas características",
        "última versión",
        "ultima version",
        "última actualización",
        "cambios recientes",
        "versiones recientes"
    ]

    /// French phrases.
    static let frenchPhrases: [String] = [
        "quoi de neuf",
        "quoi de nouveau",
        "nouveautés",
        "notes de version",
        "notes de mise à jour",
        "journal des modifications",
        "qu'est-ce qui a changé",
        "nouvelles fonctionnalités",
        "dernière version",
        "derniere version",
        "dernière mise à jour",
        "changements récents",
        "versions récentes"
    ]

    /// German phrases.
    static let germanPhrases: [String] = [
        "was ist neu",
        "neuigkeiten",
        "versionshinweise",
        "änderungsprotokoll",
        "changelog",
        "was hat sich geändert",
        "neue funktionen",
        "neueste version",
        "neueste aktualisierung",
        "letzte version",
        "aktuelle änderungen",
        "neue versionen"
    ]

    /// Japanese phrases.
    static let japanesePhrases: [String] = [
        "新機能",
        "新着",
        "変更点",
        "変更履歴",
        "更新内容",
        "アップデート内容",
        "最新バージョン",
        "最新版",
        "最新のアップデート",
        "リリースノート",
        "何が新しい",
        "何が変わった",
        "新しい機能"
    ]

    /// Simplified Chinese phrases.
    static let simplifiedChinesePhrases: [String] = [
        "新功能",
        "有什么新",
        "有哪些新",
        "更新内容",
        "更新日志",
        "更新说明",
        "版本说明",
        "版本更新",
        "最新版本",
        "最新更新",
        "发行说明",
        "更改内容",
        "改进内容",
        "新版本"
    ]

    /// Arabic phrases. Matches the "What's New" surface wording the
    /// String Catalog already ships ("ما الجديد").
    static let arabicPhrases: [String] = [
        "ما الجديد",
        "ما هو الجديد",
        "الميزات الجديدة",
        "ميزات جديدة",
        "أحدث إصدار",
        "آخر تحديث",
        "سجل التغييرات",
        "ملاحظات الإصدار",
        "ما الذي تغير",
        "التحديثات الأخيرة"
    ]

    /// Hebrew phrases. Matches the "What's New" surface wording the
    /// String Catalog already ships ("מה חדש").
    static let hebrewPhrases: [String] = [
        "מה חדש",
        "מה השתנה",
        "תכונות חדשות",
        "גרסה אחרונה",
        "גרסה אחרונה",
        "הערות גרסה",
        "עדכון אחרון",
        "יומן שינויים",
        "מה התווסף",
        "עדכונים אחרונים"
    ]
}
