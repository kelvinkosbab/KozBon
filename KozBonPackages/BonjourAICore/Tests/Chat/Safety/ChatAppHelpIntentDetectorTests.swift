//
//  ChatAppHelpIntentDetectorTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore

// MARK: - ChatAppHelpIntentDetectorTests

@Suite("ChatAppHelpIntentDetector")
struct ChatAppHelpIntentDetectorTests {

    /// Every locale's "How do I broadcast my own service?" chip. One
    /// that didn't match would answer without the real steps.
    @Test("Every localized broadcast suggestion value triggers", arguments: [
        "How do I broadcast my own service?",
        "¿Cómo transmito mi propio servicio?",
        "Comment diffuser mon propre service ?",
        "Wie sende ich meinen eigenen Dienst?",
        "自分のサービスをブロードキャストするには？",
        "如何广播我自己的服务？",
        "كيف أبث خدمتي الخاصة؟",
        "איך אני משדר שירות משלי?"
    ])
    func suggestionValuesTrigger(_ value: String) {
        #expect(ChatAppHelpIntentDetector.wantsAppHelp(message: value))
    }

    @Test("Questions about other app features trigger", arguments: [
        "How do I create a custom service type?",
        "Can I filter the list to printers?",
        "Where do I paste my API key?"
    ])
    func featureQuestionsTrigger(_ value: String) {
        #expect(ChatAppHelpIntentDetector.wantsAppHelp(message: value))
    }

    @Test("Network and concept questions don't trigger", arguments: [
        "What services are on my network?",
        "Which Apple devices are on my network?",
        "What is Matter / Thread?",
        "How do I use Siri and Shortcuts with KozBon?",
        ""
    ])
    func unrelatedQuestionsDoNotTrigger(_ value: String) {
        #expect(!ChatAppHelpIntentDetector.wantsAppHelp(message: value))
    }
}
