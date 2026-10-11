//
//  ChatSiriIntentDetectorTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore

// MARK: - ChatSiriIntentDetectorTests

@Suite("ChatSiriIntentDetector")
struct ChatSiriIntentDetectorTests {

    /// Every locale's "How do I use Siri and Shortcuts with KozBon?"
    /// chip. One that didn't match would answer without the action
    /// list in that language.
    @Test("Every localized suggestion-button value triggers", arguments: [
        "How do I use Siri and Shortcuts with KozBon?",
        "¿Cómo uso Siri y Atajos con KozBon?",
        "Comment utiliser Siri et Raccourcis avec KozBon ?",
        "Wie nutze ich Siri und Kurzbefehle mit KozBon?",
        "KozBonでSiriとショートカットを使うには？",
        "如何在 KozBon 中使用 Siri 和快捷指令？",
        "كيف أستخدم Siri والاختصارات مع KozBon؟",
        "איך משתמשים ב-Siri ובקיצורים עם KozBon?"
    ])
    func suggestionValuesTrigger(_ value: String) {
        #expect(ChatSiriIntentDetector.wantsSiriHelp(message: value))
    }

    @Test("Shortcut questions trigger without saying Siri", arguments: [
        "Can I build a shortcut that checks my printer?",
        "¿Puedo crear un atajo para mi impresora?",
        "Kann ich einen Kurzbefehl dafür anlegen?"
    ])
    func shortcutQuestionsTrigger(_ value: String) {
        #expect(ChatSiriIntentDetector.wantsSiriHelp(message: value))
    }

    @Test("Network and concept questions don't trigger", arguments: [
        "What's on my network?",
        "What is Matter?",
        "Is my printer online?",
        ""
    ])
    func unrelatedQuestionsDoNotTrigger(_ value: String) {
        #expect(!ChatSiriIntentDetector.wantsSiriHelp(message: value))
    }
}
