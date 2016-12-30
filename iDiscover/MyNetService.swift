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
  static let netServicePublishingComplete = Notification.Name(rawValue: "\(MyNetService.name).netServicePublishingComplete")
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
  
  init(service: NetService, serviceType: MyServiceType) {
    self.service = service
    self.serviceType = serviceType
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
  
  // MARK: - Stopping Resolution / Publishing
  
  func stop() {
    self.completedAddressResolution = nil
    self.publishServiceSuccess = nil
    self.publishServiceFailure = nil
    self.service.stop()
    self.isResolving = false
    self.isPublishing = false
  }
  
  // MARK: - Resolving Address
  
  var isResolving: Bool = false
  private var completedAddressResolution: (() -> Void)? = nil
  
  func resolve(completedAddressResolution: (() -> Void)? = nil) {
    self.isResolving = true
    self.completedAddressResolution = completedAddressResolution
    self.service.delegate = self
    self.service.resolve(withTimeout: 2.0)
  }
  
  // MARK: - NetServiceDelegate - Resolving Address
  
  func netServiceDidResolveAddress(_ sender: NetService) {
    print("\(self.className) : Service did resolve address \(sender) with hostname \(self.hostName)")
    self.addresses = MyAddress.parseAddresses(forNetService: sender)
    NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
    self.completedAddressResolution?()
    self.stop()
  }
  
  func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
    print("\(self.className) : Service did not resolve address \(sender)")
    NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
    self.completedAddressResolution?()
    self.stop()
  }
  
  // MARK: - Publishing Service
  
  var isPublishing: Bool = false
  private var publishServiceSuccess: (() -> Void)? = nil
  private var publishServiceFailure: (() -> Void)? = nil
  
  func publish(publishServiceSuccess: @escaping () -> Void, publishServiceFailure: @escaping () -> Void) {
    self.isPublishing = true
    self.publishServiceSuccess = publishServiceSuccess
    self.publishServiceFailure = publishServiceFailure
    self.service.delegate = self
    self.service.publish()
  }
  
  // MARK: - NetServiceDelegate - Publishing Service
  
  func netServiceDidPublish(_ sender: NetService) {
    print("\(self.className) : Service did publish \(sender)")
    NotificationCenter.default.post(name: .netServicePublishingComplete, object: self)
    self.publishServiceSuccess?()
    self.stop()
  }
  
  func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    print("\(self.className) : Service did not publish \(sender)")
    NotificationCenter.default.post(name: .netServicePublishingComplete, object: self)
    self.publishServiceFailure?()
    self.stop()
  }
}

