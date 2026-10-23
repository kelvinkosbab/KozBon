//
//  ChatAppHelpIntentDetector.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ChatAppHelpIntentDetector

/// Detects chat messages that ask how to do something in KozBon's own
/// UI — broadcasting, custom service types, sorting and filtering, or
/// choosing the AI provider — so `BonjourChatPromptBuilder` can inject
/// the `<app_help>` block. Without it the model has to guess at
/// buttons and screens, and cloud models guess confidently.
///
/// Matches feature words rather than "how do I", which would also fire
/// on every protocol question. Every locale's phrases are checked
/// against every message, and each localized "How do I broadcast my
/// own service?" suggestion contains one of them.
public enum ChatAppHelpIntentDetector {

    /// Whether the message asks about one of KozBon's features.
    public static func wantsAppHelp(message: String) -> Bool {
        let lowered = message.lowercased()
        guard !lowered.isEmpty else { return false }
        return matchPhrases.contains { lowered.contains($0) }
    }

    static let matchPhrases: [String] = [
        // en
        "broadcast", "publish", "advertise my",
        "custom service type", "custom type", "service type library",
        "filter", "sort ", "sorting",
        "ai backend", "api key", "detail level",
        // es
        "transmit", "tipo de servicio personalizado", "filtrar", "ordenar", "clave de api",
        // fr
        "diffuser", "type de service personnalisé", "filtrer", "trier", "clé api",
        // de
        "sende ich", "senden", "benutzerdefinierte", "eigenen diensttyp",
        "filtern", "sortieren", "api-schlüssel",
        // ja
        "ブロードキャスト", "カスタムサービス", "フィルタ", "並べ替え", "apiキー",
        // zh-Hans
        "广播", "自定义服务", "筛选", "排序", "api 密钥", "api密钥",
        // ar
        "أبث", "نوع خدمة مخصص", "تصفية", "فرز", "مفتاح api",
        // he
        "משדר", "לשדר", "סוג שירות מותאם", "סינון", "מיון", "מפתח api"
    ]
}
