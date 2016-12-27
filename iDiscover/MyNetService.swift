//
//  MyNetService.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

class MyNetService: NSObject, NetServiceDelegate {
  
  // Comparable
  
  static func < (lhs: MyNetService, rhs: MyNetService) -> Bool {
    if let lhsIp = lhs.ip, let rhsIp = rhs.ip {
      return lhsIp < rhsIp
    } else if let _ = lhs.ip {
      return true
    }
    return false
  }
  
  static func == (lhs: MyNetService, rhs: MyNetService) -> Bool {
    return lhs.service == rhs.service
  }
  
  // Init
  
  let service: NetService
  let serviceType: MyServiceType
  var ip: String? = nil
  
  init(service: NetService, serviceType: MyServiceType) {
    self.service = service
    self.serviceType = serviceType
  }
  
  var delegate: NetServiceDelegate? {
    get {
      return self.service.delegate
    }
    set {
      self.service.delegate = newValue
    }
  }
  
  var port: Int {
    return self.service.port
  }
  
  var hostname: String? {
    return self.service.hostName
  }
  
  var hasResolvedAddress: Bool {
    return self.port != -1
  }
  
  // MARK: - NetServiceDelegate
  
  func netServiceDidResolveAddress(_ sender: NetService) {
    print("\(self.className) : Service did resolve address \(sender)")
    self.service.stop()
  }
  
  func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
    print("\(self.className) : Service did not resolve address \(sender)")
    self.service.stop()
  }
  
  func netServiceDidPublish(_ sender: NetService) {
    print("\(self.className) : Service did publish \(sender)")
  }
  
  func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    print("\(self.className) : Service did not publish \(sender)")
  }
}
