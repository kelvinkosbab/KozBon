//
//  BonjourChatViewModelTests+ScrollToBottom.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import BonjourAI
@testable import BonjourUI

// MARK: - BonjourChatViewModelTests · Scroll-to-Bottom Button

/// When the transcript offers the scroll-to-bottom button. The
/// scroll itself needs a `ScrollViewProxy`, which tests can't build.
extension BonjourChatViewModelTests {

    @Test("Scrolled to the end, nothing is below the compose bar")
    func distanceAtEndIsZero() {
        // 1,000 pt of content, an 800 pt viewport, and a 100 pt
        // compose bar inset: the furthest offset is 300.
        let distance = BonjourChatViewModel.distanceFromBottom(
            contentHeight: 1_000,
            contentOffsetY: 300,
            containerHeight: 800,
            bottomInset: 100
        )
        #expect(distance == 0)
    }

    @Test("Content hidden behind the compose bar counts as below")
    func distanceIncludesBottomInset() {
        let distance = BonjourChatViewModel.distanceFromBottom(
            contentHeight: 1_000,
            contentOffsetY: 200,
            containerHeight: 800,
            bottomInset: 100
        )
        #expect(distance == 100)
    }

    @Test("Content shorter than the viewport is never away from the bottom")
    func shortContentIsNegative() {
        let distance = BonjourChatViewModel.distanceFromBottom(
            contentHeight: 300,
            contentOffsetY: 0,
            containerHeight: 800,
            bottomInset: 100
        )
        #expect(distance < BonjourChatViewModel.scrollToBottomThreshold)
    }

    @Test("Shows when scrolled up in a conversation")
    func showsWhenAwayWithMessages() {
        let (viewModel, _) = makeViewModel()
        viewModel.isScrolledAwayFromBottom = true
        #expect(viewModel.showsScrollToBottomButton(hasMessages: true))
    }

    @Test("Hidden at the bottom")
    func hiddenAtBottom() {
        let (viewModel, _) = makeViewModel()
        viewModel.isScrolledAwayFromBottom = false
        #expect(!viewModel.showsScrollToBottomButton(hasMessages: true))
    }

    /// A fresh chat's intro and suggestions can be taller than the
    /// screen; that isn't a conversation to jump to the end of.
    @Test("Hidden on a fresh chat even when the suggestions overflow")
    func hiddenWithoutMessages() {
        let (viewModel, _) = makeViewModel()
        viewModel.isScrolledAwayFromBottom = true
        #expect(!viewModel.showsScrollToBottomButton(hasMessages: false))
    }

    @Test("Hidden while Clear scrolls the transcript away")
    func hiddenDuringClear() {
        let (viewModel, _) = makeViewModel()
        viewModel.isScrolledAwayFromBottom = true
        viewModel.pendingClear = true
        #expect(!viewModel.showsScrollToBottomButton(hasMessages: true))
    }
}
