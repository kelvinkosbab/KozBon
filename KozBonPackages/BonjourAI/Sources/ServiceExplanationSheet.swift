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
        case service(BonjourService)
        case serviceType(BonjourServiceType)

        var displayName: String {
            switch self {
            case .service(let service):
                service.service.name
            case .serviceType(let serviceType):
                serviceType.name
            }
        }

        var serviceType: BonjourServiceType {
            switch self {
            case .service(let service):
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

    public init(service: BonjourService) {
        self.subject = .service(service)
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
                        markdownContent(explainer.explanation)
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
        case .service(let service):
            await explainer.explain(service: service)
        case .serviceType(let serviceType):
            await explainer.explain(serviceType: serviceType)
        }
    }

    // MARK: - Markdown Rendering

    @ViewBuilder
    private func markdownContent(_ text: String) -> some View {
        let lines = text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.isEmpty {
                    Spacer().frame(height: 4)
                } else if line.hasPrefix("# ") {
                    markdownText(String(line.dropFirst(2)))
                        .font(.title2).bold()
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 4)
                } else if line.hasPrefix("## ") {
                    markdownText(String(line.dropFirst(3)))
                        .font(.title3).bold()
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 4)
                } else if line.hasPrefix("### ") {
                    markdownText(String(line.dropFirst(4)))
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 2)
                } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        markdownText(String(line.dropFirst(2)))
                            .font(.body)
                    }
                } else {
                    markdownText(line)
                        .font(.body)
                }
            }
        }
        .textSelection(.enabled)
    }

    /// Renders a single line of text with inline Markdown (bold, italic, code).
    private func markdownText(_ text: String) -> Text {
        if let attributed = try? AttributedString(markdown: text) {
            return Text(attributed)
        }
        return Text(text)
    }
}

#endif
