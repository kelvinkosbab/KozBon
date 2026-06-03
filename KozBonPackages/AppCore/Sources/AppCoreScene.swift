//
//  AppCoreScene.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI
import BonjourUI
import BonjourModels
import BonjourScanning
import BonjourAI
import BonjourAIApple
import BonjourAICore
import BonjourAIAnthropic
import BonjourStorage

// MARK: - AppCoreScene

/// Root scene for the KozBon app. Thin presenter; orchestration
/// lives on ``AppCoreViewModel``.
public struct AppCoreScene: Scene {

    @State private var viewModel: AppCoreViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Cloud provider the scene-level sign-in sheet should mount
    /// for. Driven by the
    /// ``Notification.Name/aiCloudSignInRequested`` notification —
    /// the Insights long-press menu posts when the user picks
    /// the "Sign in to Claude" / "Sign in to GitHub" CTA on a
    /// cloud-backend row that lacks credentials. Hosting the
    /// sheet here (rather than inside each long-press call site)
    /// keeps the sign-in surface reachable from Discover,
    /// Library, the chat tab, and any future Insights surface
    /// without each of them having to plumb its own sheet state.
    @State private var pendingCloudSignInProvider: AICloudProvider?

    /// Production initializer — wires the default
    /// ``DependencyContainer`` and the cloud-aware factories.
    public init() {
        let credentialsStore = MainActor.assumeIsolated { KeychainAICloudCredentialsStore() }
        // ONE shared preferences store: the factories consult it
        // for routing and Settings writes through it. Separate
        // instances would each spin up their own SwiftData
        // container and writes wouldn't propagate.
        let preferencesStore = MainActor.assumeIsolated { PreferencesStore() }
        let chatFactory = CloudAwareBonjourChatSessionFactory(
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore
        )
        let explainerFactory = CloudAwareBonjourServiceExplainerFactory(
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore
        )
        self.init(
            dependencies: DependencyContainer(),
            explainerFactory: explainerFactory,
            chatSessionFactory: chatFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore
        )
    }

    /// Designated init for tests and previews; production calls
    /// the no-arg form above.
    public init(
        dependencies: DependencyContainer,
        explainerFactory: any BonjourServiceExplainerFactoryProtocol,
        chatSessionFactory: any BonjourChatSessionFactoryProtocol,
        credentialsStore: (any AICloudCredentialsStore & Sendable)? = nil,
        preferencesStore: PreferencesStore? = nil
    ) {
        _viewModel = State(initialValue: AppCoreViewModel(
            dependencies: dependencies,
            explainerFactory: explainerFactory,
            chatSessionFactory: chatSessionFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore
        ))
    }

    public var body: some Scene {
        WindowGroup {
            // `@Bindable` lets us hand a binding into
            // `TabView(selection:)` without making
            // `selectedTab` itself a `@State` here — keeping
            // the source-of-truth on the view model means
            // tests and previews can drive the selection
            // without going through SwiftUI.
            @Bindable var bindable = viewModel

            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                TabView(selection: $bindable.selectedTab) {
                    Tab(value: TopLevelDestination.bonjour) {
                        BonjourScanForServicesView(viewModel: viewModel.servicesViewModel)
                    } label: {
                        Label {
                            Text(verbatim: TopLevelDestination.bonjour.titleString)
                        } icon: {
                            TopLevelDestination.bonjour.icon
                        }
                    }

                    Tab(value: TopLevelDestination.bonjourServiceTypes) {
                        SupportedServicesView()
                    } label: {
                        Label {
                            Text(verbatim: TopLevelDestination.bonjourServiceTypes.titleString)
                        } icon: {
                            TopLevelDestination.bonjourServiceTypes.icon
                        }
                    }

                    // macOS Preferences belong in the standard
                    // Settings window (⌘,) the `Settings { }`
                    // scene below provides.
                    #if !os(macOS)
                    Tab(value: TopLevelDestination.settings) {
                        SettingsView()
                    } label: {
                        Label {
                            Text(verbatim: TopLevelDestination.settings.titleString)
                        } icon: {
                            TopLevelDestination.settings.icon
                        }
                    }
                    #endif

                    if viewModel.shouldShowChatTab {
                        // `role: .search` on iOS/visionOS places this
                        // tab at the trailing edge with Liquid Glass
                        // separation. macOS overrides any search-role
                        // tab's icon with a magnifying glass, so we
                        // use a regular Tab there to preserve our
                        // backend-specific glyph.
                        #if os(macOS)
                        Tab(value: TopLevelDestination.chat) {
                            BonjourChatView(viewModel: viewModel.servicesViewModel)
                        } label: {
                            ChatTabLabel(
                                backend: viewModel.preferencesStore.aiBackend,
                                hasUnread: viewModel.hasUnreadAssistantChatMessage
                            )
                        }
                        #else
                        Tab(value: TopLevelDestination.chat, role: .search) {
                            BonjourChatView(viewModel: viewModel.servicesViewModel)
                        } label: {
                            ChatTabLabel(
                                backend: viewModel.preferencesStore.aiBackend,
                                hasUnread: viewModel.hasUnreadAssistantChatMessage
                            )
                        }
                        #endif
                    }
                }
                #if os(macOS)
                .tabViewStyle(.automatic)
                .frame(minWidth: 800, minHeight: 500)
                #else
                // `.automatic` (not `.sidebarAdaptable`) on
                // iPad gives the floating top capsule without
                // the user-toggleable left sidebar — the
                // sidebar mode was confusing in regular size
                // class and we'd rather ship the cleaner top-
                // tab UX. iPhone keeps its bottom tabs (the
                // automatic style for compact size class) and
                // visionOS keeps its ornament tabs.
                .tabViewStyle(.automatic)
                #endif
                // Global tint stays KozBon blue so non-chat tabs
                // don't inherit the backend's accent color. Chat
                // applies the backend tint locally.
                .tint(Color.kozBonBlue)
                .environment(\.dependencies, viewModel.dependencies)
                .environment(\.serviceExplainer, viewModel.explainer)
                .environment(\.chatSession, viewModel.chatSession)
                .environment(\.preferencesStore, viewModel.preferencesStore)
                // Hands the chat surface a closure that records
                // the user as having seen the latest assistant
                // message. The scroll view fires this when the
                // user reaches the bottom edge — that's the only
                // event that should clear the tab-bar badge.
                .environment(
                    \.chatMessagesSeenAction,
                    ChatMessagesSeenAction { viewModel.markChatMessagesSeen() }
                )
                // Animate the tab-bar tint + chat-tab icon swap
                // when the backend changes mid-session.
                .animation(
                    reduceMotion ? nil : .default,
                    value: viewModel.preferencesStore.aiBackend
                )
                .task {
                    await viewModel.prewarmChatSession()
                }
                .onChange(of: viewModel.preferencesStore.aiBackend) {
                    viewModel.refreshAIBackend()
                }
                .onChange(of: viewModel.preferencesStore.aiCloudModel) {
                    viewModel.refreshAIBackend()
                }
                // Sign-in / sign-out to Claude posts this
                // notification; re-run the factories so the
                // active session reflects the new credentials.
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: .aiCloudCredentialsChanged
                    )
                ) { _ in
                    viewModel.refreshAIBackend()
                }
                .modifier(CloudSignInSheetPresentation(
                    pendingProvider: $pendingCloudSignInProvider,
                    credentialsStore: viewModel.credentialsStore
                ))
            } else {
                TabView(selection: $bindable.selectedTab) {
                    BonjourScanForServicesView(viewModel: viewModel.servicesViewModel)
                        .tabItem {
                            Label {
                                Text(verbatim: TopLevelDestination.bonjour.titleString)
                            } icon: {
                                TopLevelDestination.bonjour.icon
                            }
                        }
                        .tag(TopLevelDestination.bonjour)

                    SupportedServicesView()
                        .tabItem {
                            Label {
                                Text(verbatim: TopLevelDestination.bonjourServiceTypes.titleString)
                            } icon: {
                                TopLevelDestination.bonjourServiceTypes.icon
                            }
                        }
                        .tag(TopLevelDestination.bonjourServiceTypes)

                    if viewModel.shouldShowChatTab {
                        BonjourChatView(viewModel: viewModel.servicesViewModel)
                            .tabItem {
                                ChatTabLabel(
                                    backend: viewModel.preferencesStore.aiBackend,
                                    hasUnread: viewModel.hasUnreadAssistantChatMessage
                                )
                            }
                            .tag(TopLevelDestination.chat)
                    }

                    #if !os(macOS)
                    SettingsView()
                        .tabItem {
                            Label {
                                Text(verbatim: TopLevelDestination.settings.titleString)
                            } icon: {
                                TopLevelDestination.settings.icon
                            }
                        }
                        .tag(TopLevelDestination.settings)
                    #endif
                }
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 500)
                #endif
                // Global tint stays KozBon blue so non-chat tabs
                // don't inherit the backend's accent color. Chat
                // applies the backend tint locally.
                .tint(Color.kozBonBlue)
                .environment(\.dependencies, viewModel.dependencies)
                .environment(\.serviceExplainer, viewModel.explainer)
                .environment(\.chatSession, viewModel.chatSession)
                .environment(\.preferencesStore, viewModel.preferencesStore)
                .environment(
                    \.chatMessagesSeenAction,
                    ChatMessagesSeenAction { viewModel.markChatMessagesSeen() }
                )
                .animation(
                    reduceMotion ? nil : .default,
                    value: viewModel.preferencesStore.aiBackend
                )
                .task {
                    await viewModel.prewarmChatSession()
                }
                .onChange(of: viewModel.preferencesStore.aiBackend) {
                    viewModel.refreshAIBackend()
                }
                .onChange(of: viewModel.preferencesStore.aiCloudModel) {
                    viewModel.refreshAIBackend()
                }
                .modifier(CloudSignInSheetPresentation(
                    pendingProvider: $pendingCloudSignInProvider,
                    credentialsStore: viewModel.credentialsStore
                ))
            }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentSize)
        .commands {
            AppCommands()
        }
        #endif

        #if os(macOS)
        WindowGroup("Service Type", for: BonjourServiceType.self) { $serviceType in
            if let serviceType {
                NavigationStack {
                    SupportedServiceDetailView(serviceType: serviceType)
                }
                .frame(minWidth: 400, minHeight: 300)
            }
        }
        .defaultSize(width: 500, height: 400)

        Settings {
            SettingsView()
        }
        #endif

    }
}

// MARK: - ChatTabLabel

/// Label for the AI chat tab. In a regular horizontal size
/// class (macOS, iPad full screen, visionOS) the title swaps to
/// the active backend's brand name — "Apple Intelligence",
/// "Claude", "GitHub" — so the wide top tab capsule isn't a
/// lone glyph the user has to decode. Compact size class
/// (iPhone, iPad Slide Over) keeps the generic "Chat" / "Explore"
/// title since the icon+text pair already reads cleanly in the
/// bottom tab bar.
///
/// When `hasUnread` is true, a small red dot is painted in the
/// top-trailing corner of the brand icon. The dot is rendered
/// in-app via a `Circle` overlay rather than SwiftUI's `.badge()`
/// modifier because the iOS 18+ Liquid Glass tab bar applies its
/// own system-controlled (and noticeably larger) badge styling to
/// the trailing `role: .search` tab — going through `.badge()`
/// there gave us no size control. The overlay is identical
/// across iPhone, iPad, and macOS.
private struct ChatTabLabel: View {

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let backend: AIBackend
    let hasUnread: Bool

    var body: some View {
        Label {
            Text(titleText)
        } icon: {
            TopLevelDestination.chat.icon(activeBackend: backend)
                .overlay(alignment: .topTrailing) {
                    if hasUnread {
                        Circle()
                            .fill(.red)
                            // Halo against the tab background so
                            // the dot stays visible against both
                            // light and dark tab chrome (and against
                            // a tinted brand icon underneath).
                            .overlay {
                                Circle()
                                    .stroke(.background, lineWidth: 1)
                            }
                            .frame(width: 7, height: 7)
                            // Nudge the dot slightly outside the
                            // icon's intrinsic bounds — the tab
                            // slot is wider than the icon, so the
                            // offset doesn't get clipped.
                            .offset(x: 4, y: -2)
                            .accessibilityHidden(true)
                    }
                }
        }
    }

    private var titleText: String {
        #if os(macOS) || os(visionOS)
        // macOS / visionOS have no horizontal size class and the
        // window is always "wide" by definition.
        return String(localized: backend.displayName)
        #else
        if horizontalSizeClass == .regular {
            return String(localized: backend.displayName)
        }
        return TopLevelDestination.chat.titleString
        #endif
    }
}

// MARK: - CloudSignInSheetPresentation

/// Hosts the scene-level `AICloudSignInSheet` and the
/// notification bridge that drives it. Mounted on both the
/// modern (`TabView { Tab { ... } }`) and legacy
/// (`TabView { ... .tabItem }`) branches of `AppCoreScene.body`
/// so the Insights long-press menu's
/// ``Notification.Name/aiCloudSignInRequested`` reaches a sheet
/// presenter regardless of which OS branch is in play.
///
/// `credentialsStore == nil` is the test path (the in-memory
/// stub init); the sheet still wires up but writes are no-ops.
private struct CloudSignInSheetPresentation: ViewModifier {

    @Binding var pendingProvider: AICloudProvider?
    let credentialsStore: (any AICloudCredentialsStore & Sendable)?

    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default.publisher(for: .aiCloudSignInRequested)
            ) { note in
                guard let raw = note.userInfo?[aiCloudSignInRequestedProviderKey] as? String,
                      let provider = AICloudProvider(rawValue: raw) else { return }
                pendingProvider = provider
            }
            .sheet(item: $pendingProvider) { provider in
                if let credentialsStore {
                    AICloudSignInSheet(
                        credentialsStore: credentialsStore,
                        provider: provider
                    )
                }
            }
    }
}
