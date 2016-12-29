//
//  MyNetService.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

extension Notification.Name {
  static let netServiceResolveAddressComplete = Notification.Name(rawValue: "\(MyNetService.name).netServiceResolveAddressComplete")
}

class MyNetService: NSObject, NetServiceDelegate {
  
  // Equatable
  
  static func == (lhs: MyNetService, rhs: MyNetService) -> Bool {
    return lhs.service == rhs.service
  }
  
  // Init
  
  let service: NetService
  let serviceType: MyServiceType
  var addresses: [MyAddress] = []
  var isResolving: Bool = false
  
  var resolveAddressComplete: (() -> Void)? = nil
  
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
  
  var hostName: String {
    if let hostName = self.service.hostName {
      return hostName.replacingOccurrences(of: self.service.domain, with: "").replacingOccurrences(of: ".", with: "")
    }
    return "NA"
  }
  
  var hasResolvedAddresses: Bool {
    if let _ = self.service.addresses {
      return true
    }
    return false
  }
  
  func stop() {
    self.resolveAddressComplete = nil
    self.service.stop()
    self.isResolving = false
  }
  
  func resolve(resolveAddressComplete: (() -> Void)? = nil) {
    self.isResolving = true
    self.resolveAddressComplete = resolveAddressComplete
    self.service.delegate = self
    self.service.resolve(withTimeout: 5.0)
  }
  
  // MARK: - NetServiceDelegate
  
  func netServiceDidResolveAddress(_ sender: NetService) {
    print("\(self.className) : Service did resolve address \(sender) with hostname \(self.hostName)")
    self.addresses = MyAddress.parseAddresses(forNetService: sender)
    NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
    self.resolveAddressComplete?()
    self.stop()
  }
  
  func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
    print("\(self.className) : Service did not resolve address \(sender)")
    NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
    self.resolveAddressComplete?()
    self.stop()
  }
  
  func netServiceDidPublish(_ sender: NetService) {
    print("\(self.className) : Service did publish \(sender)")
  }
  
  func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    print("\(self.className) : Service did not publish \(sender)")
  }
}

