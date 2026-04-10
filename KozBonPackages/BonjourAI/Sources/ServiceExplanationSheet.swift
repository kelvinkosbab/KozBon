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

#if canImport(FoundationModels)
import FoundationModels

// MARK: - ServiceExplanationSheet

/// A bottom sheet that displays an AI-generated explanation of a Bonjour service.
///
/// Uses Apple's on-device FoundationModels to stream a personalized explanation
/// based on the service's metadata, addresses, and TXT records.
@available(iOS 26, macOS 26, visionOS 26, *)
public struct ServiceExplanationSheet: View {

    @Environment(\.dismiss) private var dismiss

    private let service: BonjourService
    @State private var explainer = BonjourServiceExplainer()

    public init(service: BonjourService) {
        self.service = service
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Service header
                    HStack(spacing: 10) {
                        Image(systemName: service.serviceType.imageSystemName)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text(verbatim: service.service.name)
                                .font(.headline)
                            Text(verbatim: service.serviceType.fullType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 8)

                    // AI explanation
                    if let error = explainer.error {
                        Text(error)
                            .foregroundStyle(.red)
                    } else if explainer.explanation.isEmpty && explainer.isGenerating {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(Strings.AI.generating)
                                .foregroundStyle(.secondary)
                        }
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
            .navigationTitle(String(localized: Strings.AI.insightsTitle))
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
            await explainer.explain(service: service)
        }
    }

    // MARK: - Markdown Rendering

    @ViewBuilder
    private func markdownContent(_ text: String) -> some View {
        let paragraphs = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                if paragraph.hasPrefix("# ") {
                    Text(paragraph.dropFirst(2))
                        .font(.title2).bold()
                } else if paragraph.hasPrefix("## ") {
                    Text(paragraph.dropFirst(3))
                        .font(.title3).bold()
                } else if paragraph.hasPrefix("### ") {
                    Text(paragraph.dropFirst(4))
                        .font(.headline)
                } else if paragraph.contains("\n- ") || paragraph.hasPrefix("- ") {
                    // Bullet list
                    let items = paragraph
                        .components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            if item.hasPrefix("- ") {
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    if let attributed = try? AttributedString(markdown: String(item.dropFirst(2))) {
                                        Text(attributed)
                                            .font(.body)
                                    } else {
                                        Text(String(item.dropFirst(2)))
                                            .font(.body)
                                    }
                                }
                            } else if let attributed = try? AttributedString(markdown: item) {
                                Text(attributed)
                                    .font(.body)
                            } else {
                                Text(item)
                                    .font(.body)
                            }
                        }
                    }
                } else if let attributed = try? AttributedString(markdown: paragraph) {
                    Text(attributed)
                        .font(.body)
                } else {
                    Text(paragraph)
                        .font(.body)
                }
            }
        }
        .textSelection(.enabled)
    }
}

#endif
