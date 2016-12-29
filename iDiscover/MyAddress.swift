//
//  MyAddress.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/27/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

enum MyIP {
  case v4, v6
  
  var isV4: Bool {
    return self == .v4
  }
  
  var isV6: Bool {
    return self == .v6
  }
  
  var string: String {
    switch self {
    case .v4:
      return "IPv4"
    case .v6:
      return "IPv6"
    }
  }
}

class MyAddress: Equatable {
  
  // Equatable
  
  static func == (lhs: MyAddress, rhs: MyAddress) -> Bool {
    return lhs.ip == rhs.ip && lhs.port == rhs.port && lhs.internetProtocol == rhs.internetProtocol
  }
  
  // MARK: - Properties and Init
  
  let ip: String
  let port: Int
  let internetProtocol: MyIP
  
  init(ip: String, port: Int, internetProtocol: MyIP) {
    self.ip = ip
    self.port = port
    self.internetProtocol = internetProtocol
  }
  
  var fullAddress: String {
    switch self.internetProtocol {
    case .v4:
      return "\(self.ip):\(self.port)"
    case .v6:
      return "[\(self.ip)]:\(self.port)"
    }
  }
  
  // MARK: - Static Helpers
  
  static func parseAddresses(forNetService service: NetService) -> [MyAddress] {
    return self.parseAddresses(addresses: service.addresses)
  }
  
  static func parseAddresses(addresses: [Data]?) -> [MyAddress] {
    var myAddresses: [MyAddress] = []
    
    if let addresses = addresses {
      for address in addresses {
        let data = address as NSData
        
        var inetAddress = sockaddr_in()
        data.getBytes(&inetAddress, length: MemoryLayout<sockaddr_in>.size)
        if inetAddress.sin_family == __uint8_t(AF_INET) {
          
          // IPv4
          if let ip = String(cString: inet_ntoa(inetAddress.sin_addr), encoding: .ascii) {
            let port = inetAddress.sin_port.bigEndian
            myAddresses.append(MyAddress(ip: ip, port: Int(port), internetProtocol: .v4))
          }
          
        } else if inetAddress.sin_family == __uint8_t(AF_INET6) {
          
          // IPv6
          var inetAddress6 = sockaddr_in6()
          data.getBytes(&inetAddress6, length: MemoryLayout<sockaddr_in6>.size)
          let ipStringBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
          var addr = inetAddress6.sin6_addr
          if let ipString = inet_ntop(Int32(inetAddress6.sin6_family), &addr, ipStringBuffer, __uint32_t(INET6_ADDRSTRLEN)) {
            if let ip = String(cString: ipString, encoding: .ascii) {
              
              let port = inetAddress6.sin6_port.bigEndian
              myAddresses.append(MyAddress(ip: ip, port: Int(port), internetProtocol: .v6))
            }
          }
        }
      }
    }
    return myAddresses
  }
}
