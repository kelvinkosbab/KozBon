//
//  BonjourService.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import Core

extension Notification.Name {
    static let netServiceResolveAddressComplete = Notification.Name(rawValue: "BonjourService).netServiceResolveAddressComplete")
    static let netServiceDidPublish = Notification.Name(rawValue: "BonjourServicenetServiceDidPublish")
    static let netServiceDidUnPublish = Notification.Name(rawValue: "BonjourServicenetServiceDidUnPublish")
    static let netServiceDidNotPublish = Notification.Name(rawValue: "BonjourServicenetServiceDidNotPublish")
    static let netServiceDidStop = Notification.Name(rawValue: "BonjourServicenetServiceDidStop")
}

protocol MyNetServiceDelegate : AnyObject {
    func serviceDidResolveAddress(_ service: BonjourService)
}

class BonjourService: NSObject, NetServiceDelegate {
  
  // MARK: - Init
  
  let service: NetService
  let serviceType: BonjourServiceType
  var addresses: [InternetAddress] = []
  var dataRecords: [MyDataRecord] = []
  weak var delegate: MyNetServiceDelegate?
  
  class MyDataRecord: Equatable, Comparable {
    static func == (lhs: MyDataRecord, rhs: MyDataRecord) -> Bool {
      return lhs.key == rhs.key
    }
    static func < (lhs: MyDataRecord, rhs: MyDataRecord) -> Bool {
      return lhs.key < rhs.key
    }
    let key: String
    let value: String
    init(key: String, value: String) {
      self.key = key
      self.value = value
    }
  }
  
  init(service: NetService, serviceType: BonjourServiceType) {
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
  private var didStop: (() -> Void)?
  
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
    Log.log("Service did stop \(sender)")
    NotificationCenter.default.post(name: .netServiceDidStop, object: self)
    self.isStopping = false
    self.didStop?()
    self.didStop = nil
  }
  
  // MARK: - Resolving Address
  
  var isResolving: Bool = false
  private var completedAddressResolution: (() -> Void)?
  
  func resolve(completedAddressResolution: (() -> Void)? = nil) {
    self.isResolving = true
    self.completedAddressResolution = completedAddressResolution
    self.service.delegate = self
    self.service.resolve(withTimeout: 10.0)
    self.startMonitoring()
  }
  
  // MARK: - NetServiceDelegate - Resolving Address
  
  func netServiceDidResolveAddress(_ sender: NetService) {
    Log.log("Service did resolve address \(sender) with hostname \(self.hostName)")
      self.addresses = sender.parseInternetAddresses()
    NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
    self.delegate?.serviceDidResolveAddress(self)
    self.completedAddressResolution?()
    self.completedAddressResolution = nil
    self.isResolving = false
  }
  
  func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
    Log.log("Service did not resolve address \(sender) with errorDict \(errorDict)")
    NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
    self.delegate?.serviceDidResolveAddress(self)
    self.completedAddressResolution?()
    self.completedAddressResolution = nil
    self.isResolving = false
  }
  
  // MARK: - Publishing Service
  
  var isPublishing: Bool = false
  private var publishServiceSuccess: (() -> Void)?
  private var publishServiceFailure: (() -> Void)?
  
  func publish(publishServiceSuccess: @escaping () -> Void, publishServiceFailure: @escaping () -> Void) {
    self.isPublishing = true
    self.publishServiceSuccess = publishServiceSuccess
    self.publishServiceFailure = publishServiceFailure
    self.service.delegate = self
    self.service.publish()
  }
  
  func unPublish(completion: (() -> Void)? = nil) {
    self.stop {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        NotificationCenter.default.post(name: .netServiceDidUnPublish, object: self)
        completion?()
      }
    }
  }
  
  // MARK: - NetServiceDelegate - Publishing Service
  
  func netServiceWillPublish(_ sender: NetService) {
    Log.log("Service will publish \(sender)")
  }
  
  func netServiceDidPublish(_ sender: NetService) {
    Log.log("Service did publish \(sender)")
    self.publishServiceSuccess?()
    self.publishServiceSuccess = nil
    self.publishServiceFailure = nil
    self.isPublishing = false
    NotificationCenter.default.post(name: .netServiceDidPublish, object: self)
  }
  
  func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    Log.log("Service did not publish \(sender) with errorDict \(errorDict)")
    self.publishServiceFailure?()
    self.publishServiceSuccess = nil
    self.publishServiceFailure = nil
    self.isPublishing = false
    NotificationCenter.default.post(name: .netServiceDidNotPublish, object: self)
  }
  
  // MARK: - NetServiceDelegate - TXT Records
  
  func startMonitoring() {
    self.service.startMonitoring()
  }
  
  func stopMonitoring() {
    self.service.stopMonitoring()
  }
  
  func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
    Log.log("Did update TXT record \(data)")
    
    var records: [MyDataRecord] = []
    for (key, value) in NetService.dictionary(fromTXTRecord: data) {
      if let stringValue = String(data: value, encoding: .utf8) {
        records.append(MyDataRecord(key: key, value: stringValue.isEmpty ? "NA" : stringValue))
      }
    }
      
    self.dataRecords = records.sorted { r1, r2 -> Bool in
      return r1 < r2
    }
  }
}
