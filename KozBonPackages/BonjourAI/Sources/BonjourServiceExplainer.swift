//
//  BonjourServiceExplainer.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

#if canImport(UIKit)
import UIKit
#endif

#if canImport(FoundationModels)
import FoundationModels

// MARK: - BonjourServiceExplainer

/// Uses Apple's on-device FoundationModels to explain Bonjour services to users.
///
/// Provides context-aware explanations by analyzing the service's hostname,
/// IP addresses, transport layer, TXT records, and protocol description.
@available(iOS 26, macOS 26, visionOS 26, *)
@MainActor
@Observable
public final class BonjourServiceExplainer {

    // MARK: - Properties

    /// The streamed explanation text, updated as tokens arrive.
    public var explanation: String = ""

    /// Whether the model is currently generating a response.
    public var isGenerating: Bool = false

    /// An error message if generation fails.
    public var error: String?

    private var session: LanguageModelSession?

    // MARK: - Init

    public init() {}

    // MARK: - Explain

    /// Generates a streaming explanation of the given Bonjour service.
    ///
    /// - Parameter service: The discovered Bonjour service to explain.
    public func explain(service: BonjourService) async {
        let serviceType = service.serviceType

        explanation = ""
        error = nil
        isGenerating = true

        let instructions = """
            You are a friendly networking expert helping everyday users understand \
            Bonjour (mDNS/DNS-SD) services discovered on their local network. \
            Explain what this service does, why it is likely running on the device, \
            and how the user might interact with it. Keep your explanation clear, \
            concise, and approachable — avoid deep technical jargon. \
            Use 2-4 short paragraphs. If the service has TXT records, mention what \
            they reveal about the service's configuration.
            """

        let prompt = buildPrompt(service: service, serviceType: serviceType)

        do {
            let session = LanguageModelSession(instructions: instructions)
            self.session = session

            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
                explanation = partial.content
            }
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }

    // MARK: - Device Context

    private var deviceContext: String {
        #if os(iOS)
        let device = UIDevice.current
        return "I am using an \(device.model) running \(device.systemName) \(device.systemVersion) (device name: \(device.name))"
        #elseif os(macOS)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "I am using a Mac running macOS \(osVersion) (hostname: \(ProcessInfo.processInfo.hostName))"
        #elseif os(visionOS)
        return "I am using an Apple Vision Pro running visionOS"
        #else
        return "I am using an Apple device"
        #endif
    }

    private var currentDeviceShortName: String {
        #if os(iOS)
        UIDevice.current.model
        #elseif os(macOS)
        "Mac"
        #elseif os(visionOS)
        "Apple Vision Pro"
        #else
        "device"
        #endif
    }

    // MARK: - Prompt Builder

    private func buildPrompt(service: BonjourService, serviceType: BonjourServiceType) -> String {
        var parts: [String] = []

        parts.append(deviceContext)
        parts.append("")
        parts.append("I discovered this Bonjour service on my local network and would like to understand it:")
        parts.append("")
        parts.append("Service name: \(serviceType.name)")
        parts.append("Full type: \(serviceType.fullType)")
        parts.append("Transport layer: \(serviceType.transportLayer.string.uppercased())")
        parts.append("Host name: \(service.hostName)")
        parts.append("Device advertising the service: \(service.service.name)")
        parts.append("Domain: \(service.service.domain)")

        if !service.addresses.isEmpty {
            let addressStrings = service.addresses.map(\.ipPortString)
            parts.append("IP addresses: \(addressStrings.joined(separator: ", "))")
        }

        if let detail = serviceType.detail {
            parts.append("Protocol description: \(detail)")
        }

        if !service.dataRecords.isEmpty {
            let records = service.dataRecords.map { "\($0.key)=\($0.value)" }
            parts.append("TXT records: \(records.joined(separator: ", "))")
        }

        parts.append("")
        parts.append("What does this service do, why is it running on that device, and how can I interact with it from my \(currentDeviceShortName)?")

        return parts.joined(separator: "\n")
    }
}

#endif
