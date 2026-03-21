//
//  TransportLayer.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - TransportLayer

enum TransportLayer: Int, CaseIterable, Sendable {

    case udp=0
    case tcp=1

    var string: String {
        switch self {
        case .udp:
            return "udp"
        case .tcp:
            return "tcp"
        }
    }

    var isUdp: Bool {
        return self == .udp
    }

    var isTcp: Bool {
        return self == .tcp
    }
}
