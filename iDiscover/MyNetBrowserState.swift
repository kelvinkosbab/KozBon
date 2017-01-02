//
//  MyNetBrowserState.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

enum MyServiceTypeScope {
  case all, builtIn, created
  
  var string: String {
    switch self {
    case .all:
      return "All"
    case .builtIn:
      return "Built-In"
    case .created:
      return "Created"
    }
  }
  
  var isAll: Bool {
    return self == .all
  }
  
  var isBuiltIn: Bool {
    return self == .builtIn
  }
  
  var isCreated: Bool {
    return self == .created
  }
  
  static let allScopes: [MyServiceTypeScope] = [ .all, .builtIn, .created ]
  static var allScopeTitles: [String] {
    var titles: [String] = []
    for scope in self.allScopes {
      titles.append(scope.string)
    }
    return titles
  }
}

enum MyNetServiceSortType {
  case hostNameAsc, hostNameDesc, serviceNameAsc, serviceNameDesc
  
  static let all: [MyNetServiceSortType] = [ .hostNameAsc, .hostNameDesc, .serviceNameAsc, .serviceNameDesc ]
  
  var string: String {
    switch self {
    case .hostNameAsc:
      return "Host Name ASC"
    case .hostNameDesc:
      return "Host Name DESC"
    case .serviceNameAsc:
      return "Service Name ASC"
    case .serviceNameDesc:
      return "Service Name DESC"
    }
  }
  
  func sorted(services: [MyNetService]) -> [MyNetService] {
    switch self {
    case .hostNameAsc:
      return services.sorted(by: { (service1, service2) -> Bool in
        return service1.hostName < service2.hostName
      })
      
    case .hostNameDesc:
      return services.sorted(by: { (service1, service2) -> Bool in
        return service1.hostName > service2.hostName
      })
      
    case .serviceNameAsc:
      return services.sorted(by: { (service1, service2) -> Bool in
        return service1.serviceType.name < service2.serviceType.name
      })
      
    case .serviceNameDesc:
      return services.sorted(by: { (service1, service2) -> Bool in
        return service1.serviceType.name > service2.serviceType.name
      })
    }
  }
}

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
