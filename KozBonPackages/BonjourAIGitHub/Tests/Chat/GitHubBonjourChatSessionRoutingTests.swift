//
//  GitHubBonjourChatSessionRoutingTests.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAI
import BonjourAICore
@testable import BonjourAIGitHub

// MARK: - GitHubBonjourChatSessionRoutingTests

/// Pins the error-to-action mapping inside
/// ``GitHubBonjourChatSession``. The session emits a semantic
/// ``ChatErrorAction`` per error kind so the chat banner can
/// render the right affordance (URL link vs in-app button)
/// without itself knowing about GitHub's failure taxonomy.
///
/// Split from `GitHubBonjourChatSessionTests` to keep both type
/// bodies under SwiftLint's `type_body_length` threshold; the
/// parent suite still covers streaming, multi-turn history,
/// `reset`/`restore`, and local rejection.
@Suite("GitHubBonjourChatSession · Error Routing")
@MainActor
struct GitHubBonjourChatSessionRoutingTests {

    // MARK: - Helpers

    private func makeSession(client: MockGitHubModelsClient) -> GitHubBonjourChatSession {
        let store = InMemoryAICloudCredentialsStore(seed: [.github: "ghp_test_token_1234"])
        return GitHubBonjourChatSession(client: client, credentialsStore: store)
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

    @Test("`invalidCredentials` surfaces an in-app sign-in action so the user can paste a fresh PAT")
    func invalidCredentialsRoutesToSignIn() async {
        let client = MockGitHubModelsClient(
            chunks: [],
            error: AICloudError.invalidCredentials(provider: .github)
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.errorAction?.kind == .openSignIn)
    }

    @Test("`permissionDenied` surfaces a URL link to the GitHub Models marketplace")
    func permissionDeniedRoutesToMarketplaceURL() async throws {
        let client = MockGitHubModelsClient(
            chunks: [],
            error: AICloudError.permissionDenied(
                provider: .github,
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
        #expect(url.absoluteString.contains("github.com/marketplace/models"))
    }

    @Test("`contextWindowExceeded` surfaces an in-app clear-chat action")
    func contextWindowExceededRoutesToClearChat() async {
        let client = MockGitHubModelsClient(
            chunks: [],
            error: AICloudError.contextWindowExceeded(
                provider: .github,
                message: "context length exceeded"
            )
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.errorAction?.kind == .clearChat)
    }

    @Test("`networkUnavailable` surfaces an in-app retry action")
    func networkUnavailableRoutesToRetry() async {
        let client = MockGitHubModelsClient(
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
        // Rate-limited / generic server errors surface the
        // localized message but get no action button — there's
        // no URL or in-app affordance that would help. The
        // banner falls back to the message-only shape for
        // these.
        let client = MockGitHubModelsClient(
            chunks: [],
            error: AICloudError.rateLimited(provider: .github, retryAfterSeconds: 30)
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.error != nil)
        #expect(session.errorAction == nil)
    }
}
