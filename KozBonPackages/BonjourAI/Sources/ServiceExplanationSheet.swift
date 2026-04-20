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

                    // AI explanation
                    if let error = explainer.error {
                        Text(error)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(error))
                    } else if explainer.explanation.isEmpty && explainer.isGenerating {
                        HStack(spacing: 8) {
                            ProgressView()
                                .accessibilityLabel(String(localized: Strings.AIInsights.generating))
                            Text(Strings.AIInsights.generating)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    } else {
                        MarkdownContentView(explainer.explanation)
                    }

                    if explainer.isGenerating && !explainer.explanation.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: Strings.AIInsights.insightsTitle))
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
            explainer.expertiseLevel = level
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

}

#endif
