//
//  TransportLayer.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/8/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

// MARK: - TransportLayer

enum TransportLayer: Int {
    
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
