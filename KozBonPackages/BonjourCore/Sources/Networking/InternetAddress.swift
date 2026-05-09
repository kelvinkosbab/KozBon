//
//  InternetAddress.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - InternetAddress

/// Defines an internet address endpoint.
public struct InternetAddress: Equatable, Sendable {

    // MARK: - InternetAddress Properties and Init

    /// A unique string of characters that identifies each computer using the Internet Protocol to communicate over a network.
    public let ip: String

    /// A way to identify a specific process to which an internet or other network message is to be forwarded when it arrives at a server.
    public let port: Int

    /// The version supported for sending data over the internet or other network.
    public let `protocol`: `Protocol`

    /// Creates an `InternetAddress` from its three components.
    ///
    /// All values are stored verbatim — no validation that the IP
    /// string actually parses, the port is in range, or the
    /// protocol matches the IP family. Callers (typically
    /// `BonjourService.addresses`) construct these from
    /// already-validated `NetService` data.
    ///
    /// - Parameters:
    ///   - ip: The IP address string. For `.v4` this is dotted-decimal
    ///     (`192.0.2.1`); for `.v6` this is colon-hex
    ///     (`fe80::1%en0` is acceptable).
    ///   - port: The TCP/UDP port number. `0` means "no port" by
    ///     Bonjour convention but is otherwise a valid value.
    ///   - protocol: The IP version family this address belongs to.
    public init(
        ip: String,
        port: Int,
        protocol: `Protocol`
    ) {
        self.ip = ip
        self.port = port
        self.protocol = `protocol`
    }

    // MARK: - Utilities

    /// Returns the string representation of the internet address with it's IP address and port number.
    public var ipPortString: String {
        switch self.protocol {
        case .v4:
            return "\(self.ip):\(self.port)"
        case .v6:
            return "[\(self.ip)]:\(self.port)"
        }
    }

    // MARK: - Equatable

    public static func == (
      lhs: InternetAddress,
      rhs: InternetAddress
    ) -> Bool {
        return lhs.ip == rhs.ip && lhs.port == rhs.port && lhs.protocol == rhs.protocol
    }
}

// MARK: - Protocol

public extension InternetAddress {

    /// Determines the version supported for sending data over the internet or other network.
    enum `Protocol`: Sendable {

        /// IP (version 4) addresses are 32-bit integers that can be expressed in hexadecimal notation. The
        /// more common format, known as dotted quad or dotted decimal, is x.x.x.x, where each x can be any
        /// value between 0 and 255. For example, 192.0. 2.146 is a valid IPv4 address. IPv4 still routes most of
        /// today's internet traffic.
        case v4

        /// IPv6 is an Internet Layer protocol for packet-switched internetworking and provides end-to-end datagram
        /// transmission across multiple IP networks, closely adhering to the design principles developed in the previous
        /// version of the protocol, Internet Protocol Version 4 (IPv4).
        ///
        /// In addition to offering more addresses, IPv6 also implements features not present in IPv4. It simplifies aspects
        /// of address configuration, network renumbering, and router announcements when changing network connectivity
        /// providers. It simplifies processing of packets in routers by placing the responsibility for packet fragmentation into the
        /// end points. The IPv6 subnet size is standardized by fixing the size of the host identifier portion of an address to 64 bits.
        case v6

        /// Returns the string representation of the internet protocol version.
        public var stringRepresentation: String {
            switch self {
            case .v4:
                return "IPv4"
            case .v6:
                return "IPv6"
            }
        }
    }
}
