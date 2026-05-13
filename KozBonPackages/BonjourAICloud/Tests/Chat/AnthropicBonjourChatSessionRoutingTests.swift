//
//  AnthropicBonjourChatSessionRoutingTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAI
@testable import BonjourAICloud

// MARK: - AnthropicBonjourChatSessionRoutingTests

/// Pins the error-to-action mapping inside
/// ``AnthropicBonjourChatSession``. The session emits a semantic
/// ``ChatErrorAction`` per error kind so the chat banner can
/// render the right affordance (URL link vs in-app button)
/// without itself knowing about Anthropic's failure taxonomy.
///
/// Split from `AnthropicBonjourChatSessionTests` to keep both
/// type bodies under SwiftLint's `type_body_length` threshold;
/// the parent suite still covers streaming, multi-turn history,
/// `reset`/`restore`, local rejection, and the prompt cache —
/// all of which are orthogonal to action routing.
@Suite("AnthropicBonjourChatSession · Error Routing")
@MainActor
struct AnthropicBonjourChatSessionRoutingTests {

    // MARK: - Helpers

    private func makeSession(client: MockAnthropicClient) -> AnthropicBonjourChatSession {
        let store = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test-key-1234"])
        return AnthropicBonjourChatSession(client: client, credentialsStore: store)
    }

    private func makeContext() -> BonjourChatPromptBuilder.ChatContext {
        BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: nil,
            isScanning: false
        )
    }

    // MARK: - Tests

    @Test("`invalidCredentials` surfaces an in-app sign-in action so the user can paste a fresh key")
    func invalidCredentialsRoutesToSignIn() async {
        let client = MockAnthropicClient(
            chunks: [],
            error: AICloudError.invalidCredentials(provider: .anthropic)
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.errorAction?.kind == .openSignIn)
    }

    @Test("`permissionDenied` surfaces a URL link to the plan-management console")
    func permissionDeniedRoutesToPlansURL() async throws {
        let client = MockAnthropicClient(
            chunks: [],
            error: AICloudError.permissionDenied(
                provider: .anthropic,
                message: "Plan does not include this model"
            )
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        let action = try #require(session.errorAction)
        guard case .openURL(let url) = action.kind else {
            Issue.record("Expected .openURL, got \(action.kind)")
            return
        }
        #expect(url.absoluteString.contains("anthropic.com/settings/plans"))
    }

    @Test("`contextWindowExceeded` surfaces an in-app clear-chat action")
    func contextWindowExceededRoutesToClearChat() async {
        let client = MockAnthropicClient(
            chunks: [],
            error: AICloudError.contextWindowExceeded(
                provider: .anthropic,
                message: "prompt is too long"
            )
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.errorAction?.kind == .clearChat)
    }

    @Test("`serviceOverloaded` surfaces a URL link to the status page")
    func serviceOverloadedRoutesToStatusURL() async throws {
        let client = MockAnthropicClient(
            chunks: [],
            error: AICloudError.serviceOverloaded(
                provider: .anthropic,
                message: "overloaded"
            )
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        let action = try #require(session.errorAction)
        guard case .openURL(let url) = action.kind else {
            Issue.record("Expected .openURL, got \(action.kind)")
            return
        }
        #expect(url.absoluteString.contains("status.anthropic.com"))
    }

    @Test("`networkUnavailable` surfaces an in-app retry action")
    func networkUnavailableRoutesToRetry() async {
        let client = MockAnthropicClient(
            chunks: [],
            error: AICloudError.networkUnavailable
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.errorAction?.kind == .retry)
    }

    @Test("Errors without a specific remediation leave `errorAction` nil")
    func nonRoutedErrorsLeaveActionNil() async {
        // Rate-limited, generic server errors, etc. surface the
        // localized message but get no action button — there's
        // no URL or in-app affordance that would help. The
        // banner falls back to the message-only shape for
        // these.
        let client = MockAnthropicClient(
            chunks: [],
            error: AICloudError.rateLimited(provider: .anthropic, retryAfterSeconds: 30)
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.error != nil)
        #expect(session.errorAction == nil)
    }
}
