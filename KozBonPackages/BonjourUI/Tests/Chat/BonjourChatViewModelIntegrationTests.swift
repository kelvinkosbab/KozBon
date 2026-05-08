//
//  BonjourChatViewModelIntegrationTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning
import BonjourStorage
@testable import BonjourUI

// MARK: - BonjourChatViewModelIntegrationTests

/// VM contracts that go through `BonjourServiceType.fetchAll()` —
/// either directly (the intent-dispatch handlers that look up a
/// type in the library) or transitively (the send pipeline calls
/// `buildChatContext`, which calls `fetchAll()` to populate
/// `serviceTypeLibrary`).
///
/// `fetchAll()` reads the user's custom-service-type Core Data
/// store. The Core Data model (`iDiscover.xcdatamodeld`) is only
/// compiled when Xcode builds the project — `swift test` from
/// the SPM CLI ships the package without the compiled `.momd`,
/// so any test that triggers Core Data initialization fatal-errors
/// at `MyCoreDataStack.swift:38`.
///
/// Each test in this suite first checks
/// ``MyCoreDataStack/isBundledModelAvailable`` and returns early
/// (treated as a pass) when the model isn't reachable. The result
/// is that the suite is **green-but-skip** under `swift test`
/// from the SPM CLI and **green-and-asserting** under
/// `xcodebuild test` (which compiles the model into the resource
/// bundle). The skip path keeps these tests visible in CI logs
/// — diagnostic when someone wonders why the SPM run shows them
/// as "passed but trivial."
///
/// VM tests that DON'T touch `fetchAll()` live in
/// `BonjourChatViewModelTests.swift` so the SPM CLI exercises
/// real behavior on the bulk of the surface.
@Suite("BonjourChatViewModel (Integration)")
@MainActor
struct BonjourChatViewModelIntegrationTests {

    // MARK: - Skip-on-SPM Guard

    /// Returns `true` when the Core Data model is unavailable in
    /// the current test runtime — calling sites should `return`
    /// early to skip Core-Data-dependent assertions. The skip is
    /// silent (the test reports as a pass with no `#expect`
    /// failures) so the SPM CLI run stays green.
    private func skipIfCoreDataUnavailable() -> Bool {
        !MyCoreDataStack.isBundledModelAvailable
    }

    // MARK: - Helpers

    // 3-tuple is fine for a private test helper. See sibling
    // file `BonjourChatViewModelTests.swift` for full rationale.
    // swiftlint:disable:next large_tuple
    private func makeServices() -> (BonjourServicesViewModel, MockBonjourServiceScanner, MockBonjourPublishManager) {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let services = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager
        )
        return (services, scanner, publishManager)
    }

    private func makeViewModel() -> (BonjourChatViewModel, MockBonjourPublishManager) {
        let (services, _, publishManager) = makeServices()
        return (BonjourChatViewModel(services: services), publishManager)
    }

    private func attachMockSession(
        to viewModel: BonjourChatViewModel,
        cannedReply: String = "Test reply"
    ) -> MockBonjourChatSession {
        let mock = MockBonjourChatSession(cannedReply: cannedReply)
        viewModel.localSession = mock
        return mock
    }

    private func makePreferencesStore(
        expertiseLevel: String = UserPreferences.defaultAIExpertiseLevel
    ) -> PreferencesStore {
        let store = PreferencesStore()
        store.aiExpertiseLevel = expertiseLevel
        return store
    }

    // MARK: - Send Pipeline (Goes Through `buildChatContext` → `fetchAll`)

    @Test("`sendMessage` clears `inputText` immediately, before any awaits")
    func sendMessageClearsInputText() async {
        if skipIfCoreDataUnavailable() { return }
        let (vm, _) = makeViewModel()
        let mock = attachMockSession(to: vm)
        let store = makePreferencesStore()
        vm.inputText = "Hello"
        await vm.sendMessage("Hello", using: mock, preferencesStore: store, reduceMotion: true)
        #expect(vm.inputText.isEmpty)
    }

    @Test("`sendMessage` appends the user bubble before kicking off `send` on the session")
    func sendMessageAppendsUserBeforeSend() async {
        if skipIfCoreDataUnavailable() { return }
        let (vm, _) = makeViewModel()
        let mock = attachMockSession(to: vm)
        let store = makePreferencesStore()
        await vm.sendMessage("Hello", using: mock, preferencesStore: store, reduceMotion: true)
        // Append fired exactly once via the synchronous protocol
        // call, before `send` started its await chain. The mock's
        // `send` then appends the assistant bubble.
        #expect(mock.appendUserMessageCallCount == 1)
        #expect(mock.sendCallCount == 1)
        #expect(mock.messages.count == 2)
        #expect(mock.messages[0].role == .user)
        #expect(mock.messages[0].content == "Hello")
        #expect(mock.messages[1].role == .assistant)
    }

    @Test("`sendMessage` propagates the user's expertise level into the session's response length")
    func sendMessageSetsResponseLengthFromExpertise() async {
        if skipIfCoreDataUnavailable() { return }
        let (vm, _) = makeViewModel()
        let mock = attachMockSession(to: vm)
        let store = makePreferencesStore(expertiseLevel: "technical")
        await vm.sendMessage("Hello", using: mock, preferencesStore: store, reduceMotion: true)
        // Technical → thorough; Basic → standard. The contract is
        // pinned in `BonjourServicePromptBuilder.ExpertiseLevel.responseLength`.
        #expect(mock.responseLength == .thorough)
    }

    @Test("`sendMessage` defaults to basic-level response length when expertise pref is unset / unknown")
    func sendMessageDefaultsToBasicWhenExpertiseUnknown() async {
        if skipIfCoreDataUnavailable() { return }
        let (vm, _) = makeViewModel()
        let mock = attachMockSession(to: vm)
        // Storing an unknown raw value forces the
        // `BonjourServicePromptBuilder.ExpertiseLevel(rawValue:)`
        // init to fail and the VM to fall through to `.basic`.
        let store = makePreferencesStore(expertiseLevel: "wat")
        await vm.sendMessage("Hello", using: mock, preferencesStore: store, reduceMotion: true)
        #expect(mock.responseLength == .standard)
    }

    @Test("`sendMessage` runs the full pipeline twice without leaking state across calls")
    func sendMessageRunsTwiceCleanly() async {
        if skipIfCoreDataUnavailable() { return }
        // The VM's no-op-when-already-generating guard runs on the
        // synchronous frame BEFORE any await — so two awaited
        // sends in sequence both reach `send` because the mock's
        // first call has already toggled `isGenerating` back to
        // false by the time the second send checks the guard. The
        // contract under test here is "two sequential awaited sends
        // both run cleanly" — the actual concurrent-guard race is
        // structural, exercised in production by the streaming
        // window.
        let (vm, _) = makeViewModel()
        let mock = attachMockSession(to: vm)
        let store = makePreferencesStore()
        await vm.sendMessage("First", using: mock, preferencesStore: store, reduceMotion: true)
        #expect(mock.sendCallCount == 1)
        await vm.sendMessage("Second", using: mock, preferencesStore: store, reduceMotion: true)
        #expect(mock.sendCallCount == 2)
    }

    // MARK: - Build Chat Context (Cached Path)

    @Test("`buildChatContext` returns the cached snapshot when the message isn't a network-state question")
    func buildChatContextCachedPath() async {
        if skipIfCoreDataUnavailable() { return }
        let (vm, _) = makeViewModel()
        let context = await vm.buildChatContext(forMessage: "What is Matter?")
        // Cached path: lastScanTime / isScanning come from the
        // services VM (both nil/false on a fresh mock setup).
        #expect(context.lastScanTime == nil)
        #expect(context.isScanning == false)
        // Library is whatever `BonjourServiceType.fetchAll()`
        // returns — non-empty in any real run.
        #expect(!context.serviceTypeLibrary.isEmpty)
    }

    @Test("`buildChatContext` populates the library snapshot independently of the question")
    func buildChatContextIncludesLibrary() async {
        if skipIfCoreDataUnavailable() { return }
        let (vm, _) = makeViewModel()
        let context = await vm.buildChatContext(forMessage: "Hello")
        #expect(!context.serviceTypeLibrary.isEmpty)
    }

    // MARK: - Intent Dispatch (Calls `BonjourServiceType.fetchAll`)

    @Test("`handlePendingIntent` for `.broadcastService` resolves the type and populates the broadcast slot")
    func handleBroadcastIntentResolvedType() {
        if skipIfCoreDataUnavailable() { return }
        let (vm, _) = makeViewModel()
        let mock = attachMockSession(to: vm)
        // `_http._tcp` is a built-in type, so the library lookup
        // succeeds and the broadcast slot fills.
        let intent = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_http._tcp",
            port: 8080,
            domain: "local.",
            txtRecords: []
        )
        vm.handlePendingIntent(intent, injectedSession: mock)
        #expect(vm.pendingBroadcastIntent != nil)
        #expect(vm.pendingBroadcastIntent?.serviceType.fullType == "_http._tcp")
        #expect(vm.pendingBroadcastIntent?.port == 8080)
        #expect(vm.pendingBroadcastIntent?.domain == "local.")
        #expect(mock.intentBroker.pendingIntent == nil)
    }

    @Test("`handlePendingIntent` for `.broadcastService` with an unknown type leaves the slot nil but still consumes the broker")
    func handleBroadcastIntentUnknownType() {
        if skipIfCoreDataUnavailable() { return }
        let (vm, _) = makeViewModel()
        let mock = attachMockSession(to: vm)
        let intent = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_nonsense_does_not_exist._tcp",
            port: 8080,
            domain: "local.",
            txtRecords: []
        )
        vm.handlePendingIntent(intent, injectedSession: mock)
        // No pending broadcast — the type lookup failed.
        #expect(vm.pendingBroadcastIntent == nil)
        // But the broker is still consumed so the failed intent
        // doesn't keep re-firing on every render.
        #expect(mock.intentBroker.pendingIntent == nil)
    }

    @Test("`handlePendingIntent` for `.deleteCustomServiceType` populates the dialog when the type is found")
    func handleDeleteIntentResolvedType() {
        if skipIfCoreDataUnavailable() { return }
        // Delete intent against `_http._tcp` looks up the type
        // successfully — so it populates the dialog. (The actual
        // "you can't delete built-ins" guard lives in the AI tool's
        // preflight, not in this VM dispatch.)
        let (vm, _) = makeViewModel()
        let mock = attachMockSession(to: vm)
        let intent = BonjourChatIntent.deleteCustomServiceType(serviceTypeFullType: "_http._tcp")
        vm.handlePendingIntent(intent, injectedSession: mock)
        #expect(vm.pendingDeleteCustomServiceType != nil)
        #expect(vm.pendingDeleteCustomServiceType?.fullType == "_http._tcp")
        #expect(mock.intentBroker.pendingIntent == nil)
    }
}
