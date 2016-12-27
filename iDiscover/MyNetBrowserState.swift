//
//  MyNetBrowserState.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

enum MyNetServiceBrowserState {
  case stopped, searching
  
  var string: String {
    switch self {
    case .stopped:
      return "Stopped"
    case .searching:
      return "Searching"
    }
  }
  
  var isStopped: Bool {
    return self == .stopped
  }
  
  var isSearching: Bool {
    return self == .searching
  }
}

enum MyTransportLayer: Int {
  case udp=0, tcp=1
  
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
