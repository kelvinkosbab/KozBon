//
//  TransportLayer.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - TransportLayer

public enum TransportLayer: Int, CaseIterable, Sendable, Codable {

    case udp=0
    case tcp=1

    public var string: String {
        switch self {
        case .udp:
            return "udp"
        case .tcp:
            return "tcp"
        }
    }

    public var isUdp: Bool {
        return self == .udp
    }

    public var isTcp: Bool {
        return self == .tcp
    }
}
