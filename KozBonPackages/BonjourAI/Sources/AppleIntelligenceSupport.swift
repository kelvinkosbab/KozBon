//
//  AppleIntelligenceSupport.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - AppleIntelligenceSupport

/// Utilities for checking whether Apple Intelligence can be supported on this device.
public enum AppleIntelligenceSupport {

    /// Whether this device is capable of supporting Apple Intelligence.
    ///
    /// Returns `true` if the device has the hardware and OS version to run
    /// on-device AI models, even if the user hasn't enabled Apple Intelligence yet.
    /// Returns `false` on devices that cannot support Apple Intelligence at all
    /// (e.g., older hardware).
    public static var isDeviceSupported: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            case .unavailable(let reason):
                return reason != .deviceNotEligible
            @unknown default:
                return false
            }
        }
        return false
        #else
        return false
        #endif
    }
}
