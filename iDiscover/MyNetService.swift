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
  static let netServiceDidPublish = Notification.Name(rawValue: "\(MyNetService.name).netServiceDidPublish")
  static let netServiceDidUnPublish = Notification.Name(rawValue: "\(MyNetService.name).netServiceDidUnPublish")
  static let netServiceDidNotPublish = Notification.Name(rawValue: "\(MyNetService.name).netServiceDidNotPublish")
  static let netServiceDidStop = Notification.Name(rawValue: "\(MyNetService.name).netServiceDidStop")
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
      return hostName.replacingOccurrences(of: self.service.domain, with: "").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "-", with: " ")
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
  
  var isStopping: Bool = false
  private var didStop: (() -> Void)? = nil
  
  func stop(didStop: (() -> Void)? = nil) {
    self.isStopping = true
    self.isResolving = false
    self.isPublishing = false
    self.didStop = didStop
    self.completedAddressResolution = nil
    self.publishServiceSuccess = nil
    self.publishServiceFailure = nil
    self.service.stop()
  }
  
  // MARK: - NetServiceDelegate - Stopping
  
  func netServiceDidStop(_ sender: NetService) {
    print("\(self.className) : Service did stop \(sender)")
    NotificationCenter.default.post(name: .netServiceDidStop, object: self)
    self.isStopping = false
    self.didStop?()
    self.didStop = nil
  }
  
  // MARK: - Resolving Address
  
  var isResolving: Bool = false
  private var completedAddressResolution: (() -> Void)? = nil
  
  func resolve(completedAddressResolution: (() -> Void)? = nil) {
    self.isResolving = true
    self.completedAddressResolution = completedAddressResolution
    self.service.delegate = self
    self.service.resolve(withTimeout: 5.0)
  }
  
  // MARK: - NetServiceDelegate - Resolving Address
  
  func netServiceDidResolveAddress(_ sender: NetService) {
    print("\(self.className) : Service did resolve address \(sender) with hostname \(self.hostName)")
    self.addresses = MyAddress.parseAddresses(forNetService: sender)
    NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
    self.completedAddressResolution?()
    self.completedAddressResolution = nil
    self.isResolving = false
  }
  
  func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
    print("\(self.className) : Service did not resolve address \(sender) with errorDict \(errorDict)")
    NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
    self.completedAddressResolution?()
    self.completedAddressResolution = nil
    self.isResolving = false
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
    self.service.publish(options: [.listenForConnections])
  }
  
  func unPublish(completion: (() -> Void)? = nil) {
    self.stop {
      DispatchQueue.main.asyncAfter(after: 0.5, closure: {
        NotificationCenter.default.post(name: .netServiceDidUnPublish, object: self)
        completion?()
      })
    }
  }
  
  // MARK: - NetServiceDelegate - Publishing Service
  
  func netServiceDidPublish(_ sender: NetService) {
    print("\(self.className) : Service did publish \(sender)")
    self.publishServiceSuccess?()
    self.publishServiceSuccess = nil
    self.publishServiceFailure = nil
    self.isPublishing = false
    NotificationCenter.default.post(name: .netServiceDidPublish, object: self)
  }
  
  func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    print("\(self.className) : Service did not publish \(sender) with errorDict \(errorDict)")
    self.publishServiceFailure?()
    self.publishServiceSuccess = nil
    self.publishServiceFailure = nil
    self.isPublishing = false
    NotificationCenter.default.post(name: .netServiceDidNotPublish, object: self)
  }
  
  // MARK: - NetServiceDelegate
  
  func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
    print("\(self.className) : Did update TXT record \(data)")
  }
}
