//
//  TransportLayer.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - TransportLayer

/// The network transport protocol used by a Bonjour service.
///
/// Bonjour services advertise themselves over either UDP or TCP. This enum
/// represents that choice and is used throughout the app to construct
/// full service type strings (e.g., `_http._tcp`) and to filter or
/// display services by their transport layer.
///
/// Raw values are persisted in Core Data (`CustomServiceType.transportLayerValue`)
/// so they must remain stable: UDP = 0, TCP = 1.
public enum TransportLayer: Int, CaseIterable, Sendable, Codable {

    /// User Datagram Protocol — connectionless, lower overhead.
    ///
    /// Used by services like mDNS, SSDP, CoAP, and AirPlay (discovery).
    case udp = 0

    /// Transmission Control Protocol — connection-oriented, reliable delivery.
    ///
    /// Used by the majority of Bonjour services including HTTP, SSH, AirPlay
    /// (streaming), HomeKit, and file sharing protocols.
    case tcp = 1

    /// The lowercase protocol string used in Bonjour type identifiers (e.g., `"tcp"` or `"udp"`).
    public var string: String {
        switch self {
        case .udp:
            return "udp"
        case .tcp:
            return "tcp"
        }
    }

    /// Whether this transport layer is UDP.
    public var isUdp: Bool {
        return self == .udp
    }

    /// Whether this transport layer is TCP.
    public var isTcp: Bool {
        return self == .tcp
    }
}
