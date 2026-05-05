//
//  ChatScanIntentDetector.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ChatScanIntentDetector

/// Heuristic detector that decides whether a chat message should
/// trigger a fresh Bonjour scan before the assistant answers.
///
/// The chat surface defaults to passing the live-but-cached
/// `BonjourServicesViewModel.flatActiveServices` snapshot into the
/// model's context block. That snapshot is fine for questions
/// about *concepts* — "what is Matter?", "explain HomeKit" — but
/// can be stale for questions about *current state* — "what's on
/// my network?", "list my discovered devices." For the latter,
/// we want the model to see fresh data.
///
/// The matcher is deliberately lenient: false positives (running
/// a fresh scan when the user just wanted a concept explanation)
/// cost ~3 seconds of extra latency before the first token arrives.
/// False negatives (skipping the fresh scan when the user wanted
/// live state) cost the user *wrong answers*. Wrong answers are
/// the worse failure mode, so the phrase list bias toward over-
/// matching.
///
/// Localized for the six languages KozBon ships in: English,
/// Spanish, French, German, Japanese, and Simplified Chinese.
/// Phrases from every language are checked against every input —
/// users typing English on a Spanish device, or mixing languages
/// in a single sentence, still get the fresh-scan path. Cross-
/// language false positives are theoretically possible but rare
/// in practice because the high-signal phrases are deliberately
/// distinctive (verbs and possessive constructions don't usually
/// appear as substrings of unrelated words across languages).
public enum ChatScanIntentDetector {

    // MARK: - Public API

    /// Returns `true` when the user's message looks like a question
    /// about live network state — services, devices, broadcasts —
    /// where stale cached data would mislead the assistant.
    ///
    /// - Parameter message: The user's trimmed input text. The
    ///   matcher lowercases internally; callers don't need to.
    /// - Returns: Whether the chat surface should run a fresh
    ///   `BonjourOneShotScanner` pass before constructing the
    ///   assistant's context.
    public static func wantsFreshScan(message: String) -> Bool {
        let lowered = message.lowercased()
        guard !lowered.isEmpty else { return false }
        for phrase in matchPhrases where lowered.contains(phrase) {
            return true
        }
        return false
    }

    // MARK: - Phrase Lists

    /// All localized phrase lists concatenated into a single array
    /// so ``wantsFreshScan(message:)`` does one linear scan per
    /// invocation. The per-language lists below are the
    /// authoritative source — this combined array is constructed
    /// once at process start.
    static let matchPhrases: [String] =
        englishPhrases
        + spanishPhrases
        + frenchPhrases
        + germanPhrases
        + japanesePhrases
        + simplifiedChinesePhrases

    /// English phrases. Grouped by signal type for readability —
    /// possessive + state-noun phrasings, "what's around" question
    /// stems, action verbs implying "look right now," and listing/
    /// showing requests.
    static let englishPhrases: [String] = [
        // Possessive + state nouns: the strongest signal that the
        // user is asking about THEIR network, not the concept of
        // networks in general.
        "my network",
        "my services",
        "my devices",
        "my broadcasts",
        "my broadcast",
        "your network",

        // "What's out there right now" question stems.
        "what's on",
        "what is on",
        "what's connected",
        "what is connected",
        "anything on my",
        "anything connected",
        "what services",
        "which services",
        "how many services",
        "what devices",
        "which devices",
        "how many devices",
        "what's broadcasting",
        "what is broadcasting",
        "currently advertising",
        "currently broadcasting",
        "on my network",
        "on the network",
        "on this network",
        "on the local network",

        // Action verbs that imply "go look now."
        "scan",
        "rescan",
        "refresh",
        "discover services",
        "discover devices",

        // Listing / showing — asks for an enumeration of current state.
        "list services",
        "list devices",
        "list discovered",
        "list active",
        "list all services",
        "list all devices",
        "show services",
        "show devices",
        "show discovered",
        "show active",
        "show me services",
        "show me devices",
        "show me what",

        // Discovery vocabulary the assistant itself uses, which
        // users tend to mirror back in follow-up questions.
        "discovered services",
        "discovered devices",
        "available services",
        "available devices",
        "active services",
        "active devices",

        // Find-by-category — the user is asking whether a specific
        // class of thing is on the network right now.
        "find services",
        "find devices",
        "find printers",
        "find airplay",
        "find chromecast",
        "find homekit",
        "find matter",
        "find thread",
        "find sonos",
        "find spotify"
    ]

    /// Spanish phrases. Mirrors the English coverage with the
    /// possessive-state-noun, what's-out-there, action-verb, and
    /// listing groupings. "Escanear" / "buscar" are the strongest
    /// imperatives; "mi red" / "mis dispositivos" carry the
    /// possessive signal.
    static let spanishPhrases: [String] = [
        "mi red",
        "mis servicios",
        "mis dispositivos",
        "qué hay en",
        "qué está conectado",
        "qué servicios",
        "qué dispositivos",
        "cuántos servicios",
        "cuántos dispositivos",
        "escanear",
        "escaneo",
        "actualizar",
        "descubrir",
        "descubiertos",
        "listar servicios",
        "listar dispositivos",
        "mostrar servicios",
        "mostrar dispositivos",
        "buscar servicios",
        "buscar dispositivos",
        "buscar impresoras",
        "en la red",
        "en mi red",
        "transmitiendo"
    ]

    /// French phrases. "Scanner" overlaps with English "scan" but
    /// French speakers using the verb still want a scan, so the
    /// match is correct either way. "Mon réseau" and "mes
    /// appareils" carry the possessive signal.
    static let frenchPhrases: [String] = [
        "mon réseau",
        "mes services",
        "mes appareils",
        "quels services",
        "quels appareils",
        "combien de services",
        "combien d'appareils",
        "qu'est-ce qu'il y a",
        "qu'y a-t-il",
        "est connecté",
        "scanner",
        "rafraîchir",
        "actualiser",
        "découvrir",
        "découverts",
        "lister les services",
        "lister les appareils",
        "afficher les services",
        "afficher les appareils",
        "trouver des services",
        "trouver des appareils",
        "trouver des imprimantes",
        "sur le réseau",
        "sur mon réseau",
        "diffuse"
    ]

    /// German phrases. "Mein Netzwerk" / "meine Geräte" carry the
    /// possessive signal. German compounds mean "scan" appears in
    /// "scannen", "neu scannen", etc. — substring matching catches
    /// those automatically.
    static let germanPhrases: [String] = [
        "mein netzwerk",
        "meine dienste",
        "meine geräte",
        "welche dienste",
        "welche geräte",
        "wie viele dienste",
        "wie viele geräte",
        "ist verbunden",
        "scannen",
        "neu scannen",
        "aktualisieren",
        "entdecken",
        "entdeckte",
        "auflisten",
        "dienste anzeigen",
        "geräte anzeigen",
        "drucker finden",
        "geräte finden",
        "im netzwerk",
        "in meinem netzwerk",
        "sendet"
    ]

    /// Japanese phrases. Japanese sentences don't use spaces between
    /// words, so substring matching is the natural fit. Phrases use
    /// katakana for loanwords ("スキャン" = scan, "サービス" =
    /// service) and kanji/kana for native vocabulary.
    static let japanesePhrases: [String] = [
        "ネットワーク",
        "サービス",
        "デバイス",
        "機器",
        "スキャン",
        "再スキャン",
        "更新",
        "リスト",
        "表示",
        "見せて",
        "探して",
        "見つけて",
        "発見",
        "ブロードキャスト",
        "接続",
        "いくつ",
        "いくつの",
        "私のネットワーク",
        "私のサービス",
        "私のデバイス",
        "ネットワーク上",
        "ネットワークに"
    ]

    /// Simplified Chinese phrases. Like Japanese, no inter-word
    /// spaces, so substring matching works directly. Possessive
    /// uses "我的" ("my"); action verbs lead with "扫描" (scan),
    /// "刷新" (refresh), "查找" (find).
    static let simplifiedChinesePhrases: [String] = [
        "我的网络",
        "我的服务",
        "我的设备",
        "什么服务",
        "什么设备",
        "哪些服务",
        "哪些设备",
        "多少服务",
        "多少设备",
        "扫描",
        "重新扫描",
        "刷新",
        "发现",
        "已发现",
        "列出服务",
        "列出设备",
        "显示服务",
        "显示设备",
        "查找",
        "查找服务",
        "查找设备",
        "查找打印机",
        "网络上",
        "在网络上",
        "广播"
    ]
}
