//
//  ServiceExplanationSheet.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourModels
import BonjourLocalization
import BonjourStorage

#if canImport(FoundationModels)
import FoundationModels

// MARK: - ServiceExplanationSheet

/// A bottom sheet that displays an AI-generated explanation of a Bonjour service.
///
/// Uses Apple's on-device FoundationModels to stream a personalized explanation
/// based on the service's metadata, addresses, and TXT records.
@available(iOS 26, macOS 26, visionOS 26, *)
public struct ServiceExplanationSheet: View {

    /// The subject to explain — either a discovered service or a service type from the library.
    @MainActor
    enum Subject {
        case service(BonjourService, isPublished: Bool)
        case serviceType(BonjourServiceType)

        var displayName: String {
            switch self {
            case .service(let service, _):
                service.service.name
            case .serviceType(let serviceType):
                serviceType.name
            }
        }

        var serviceType: BonjourServiceType {
            switch self {
            case .service(let service, _):
                service.serviceType
            case .serviceType(let serviceType):
                serviceType
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.serviceExplainer) private var injectedExplainer
    @Environment(\.preferencesStore) private var preferencesStore

    private let subject: Subject
    @State private var localExplainer = BonjourServiceExplainer()

    /// Fires a subtle haptic tap as each new sentence lands from the
    /// streaming explanation. Mirrors the chat view's behavior so both
    /// "model is streaming" surfaces feel identical. See
    /// `SentenceHapticTracker` for the detection rules.
    @State private var sentenceHapticTracker = SentenceHapticTracker()

    /// The active explainer — uses the injected one if available, otherwise the local instance.
    private var explainer: any BonjourServiceExplainerProtocol {
        injectedExplainer ?? localExplainer
    }

    public init(service: BonjourService, isPublished: Bool = false) {
        self.subject = .service(service, isPublished: isPublished)
    }

    public init(serviceType: BonjourServiceType) {
        self.subject = .serviceType(serviceType)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Service header
                    HStack(spacing: 10) {
                        Image(systemName: subject.serviceType.imageSystemName)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text(verbatim: subject.displayName)
                                .font(.headline)
                            Text(verbatim: subject.serviceType.fullType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Streaming explanation — mirrors the chat view's
                    // streaming surface so both Insights presentations feel
                    // the same:
                    //   - Pre-first-token: `TypingIndicator` + "Generating…"
                    //     label (not a default spinner — we established the
                    //     three-dot bubble as the app's "model is working"
                    //     visual).
                    //   - First token onward: rendered Markdown, with the
                    //     typing indicator pinned below until streaming
                    //     ends so the user can see more is coming.
                    //   - Per-sentence haptic tap via `SentenceHapticTracker`
                    //     matches `BonjourChatView` tactile rhythm.
                    if let error = explainer.error {
                        Text(error)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(error))
                    } else if explainer.explanation.isEmpty && explainer.isGenerating {
                        HStack(spacing: 8) {
                            TypingIndicator()
                                .accessibilityLabel(String(localized: Strings.Insights.generating))
                            Text(Strings.Insights.generating)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    } else {
                        MarkdownContentView(explainer.explanation)
                    }

                    if explainer.isGenerating && !explainer.explanation.isEmpty {
                        // Pinned to the leading edge so the indicator
                        // reads as the "next sentence is arriving here"
                        // marker — aligned with where the next token
                        // will render — rather than a centered system
                        // spinner that feels detached from the text
                        // flow.
                        TypingIndicator()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(String(localized: Strings.Insights.generating))
                    }
                }
                .padding()
            }
            // Per-sentence haptic during streaming. `.sensoryFeedback`
            // fires once per `tickCount` increment; the tracker handles
            // detection (one tap per completed sentence, final sentence
            // ticks once on stream end). Guarded out on visionOS where
            // the modifier is 26-only and our deployment target is 2.0.
            #if !os(visionOS)
            .sensoryFeedback(.impact(weight: .light), trigger: sentenceHapticTracker.tickCount)
            #endif
            .onChange(of: explainer.explanation) { _, _ in
                forwardStreamingStateToHapticTracker()
            }
            .onChange(of: explainer.isGenerating) { _, _ in
                forwardStreamingStateToHapticTracker()
            }
            .navigationTitle(String(localized: Strings.Insights.insightsTitle))
            .accessibilityIdentifier("ai_explanation_sheet")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(String(localized: Strings.Buttons.done), systemImage: Iconography.confirm)
                    }
                }

            }
        }
        .task {
            let level = BonjourServicePromptBuilder.ExpertiseLevel(
                rawValue: preferencesStore.aiExpertiseLevel
            ) ?? .basic
            let length = BonjourServicePromptBuilder.ResponseLength(
                rawValue: preferencesStore.aiResponseLength
            ) ?? .standard
            explainer.expertiseLevel = level
            explainer.responseLength = length
            await explainSubject()
        }
    }

    // MARK: - Explain

    private func explainSubject() async {
        switch subject {
        case .service(let service, let isPublished):
            await explainer.explain(service: service, isPublished: isPublished)
        case .serviceType(let serviceType):
            await explainer.explain(serviceType: serviceType)
        }
    }

    // MARK: - Haptic Forwarding

    /// Pushes the current explainer state into the sentence-haptic
    /// tracker so `.sensoryFeedback` fires a light tap per newly
    /// completed sentence. Mirrors the chat view's approach exactly;
    /// the only difference here is there's a single response per
    /// sheet (no message-id reset needed between turns).
    private func forwardStreamingStateToHapticTracker() {
        sentenceHapticTracker.onStreamingStateChanged(
            content: explainer.explanation,
            isFinal: !explainer.isGenerating
        )
    }

}

#endif
