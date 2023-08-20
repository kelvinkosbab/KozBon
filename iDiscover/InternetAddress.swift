//
//  MyAddress.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/27/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

// MARK: - InternetAddress

/// Defines an internet address endpoint.
public struct InternetAddress : Equatable {
    
    // MARK: - Protocol
    
    /// Determines the versions supported for sending data over the internet or other network.
    public enum `Protocol` {
        
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
        var stringRepresentation: String {
            switch self {
            case .v4:
                return "IPv4"
            case .v6:
                return "IPv6"
            }
        }
    }
    
    // MARK: - InternetAddress Properties and Init
    
    public let ip: String
    public let port: Int
    public let `protocol`: `Protocol`
    
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

// MARK: - NetService & InternetAddress

public extension NetService {
    
    func parseInternetAddresses() -> [InternetAddress]
}


class MyAddress: Equatable {
  
  
  
  
  
  
  
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
