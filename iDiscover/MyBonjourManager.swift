//
//  MyBonjourManager.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/24/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

extension Notification.Name {
  static let bonjourDidAddService = Notification.Name(rawValue: "\(MyBonjourManager.name).bonjourDidAddService")
  static let bonjourDidRemoveService = Notification.Name(rawValue: "\(MyBonjourManager.name).bonjourDidRemoveService")
  static let bonjourDidClearServices = Notification.Name(rawValue: "\(MyBonjourManager.name).bonjourDidClearServices")
}

protocol MyBonjourManagerDelegate : class {
  func servicesDidUpdate(_ services: [MyNetService])
}

class MyBonjourManager: NSObject {
  
  // MARK: - Singleton
  
  static let shared = MyBonjourManager()
  
  private override init() { super.init() }
  
  // MARK: - Properties
  
  weak var delegate: MyBonjourManagerDelegate? = nil
  
  var completion: ((_ services: [MyNetService]) -> Void)? = nil
  
  private var serviceBrowsers: [MyNetServiceBrowser] = []
  
  var sortType: MyNetServiceSortType? = nil {
    didSet {
      if let sortType = self.sortType {
        self.services = sortType.sorted(services: self.services)
      }
    }
  }
  
  // MARK: - Service Browser State
  
  private var browserState: MyNetServiceBrowserState {
    for serviceBrowser in self.serviceBrowsers {
      if serviceBrowser.state.isSearching {
        return .searching
      }
    }
    return.stopped
  }
  
  // MARK: - Resolving Addresses
  
  private var isResolvingFoundServiceAddresses: Bool {
    for service in self.services {
      if service.isResolving {
        return true
      }
    }
    return false
  }
  
  // MARK: - Completed Discovery Process
  
  var isProcessing: Bool {
    return self.browserState.isSearching || self.isResolvingFoundServiceAddresses
  }
  
  private func checkDiscoveryCompletion() {
    if !self.isProcessing {
      self.completion?(self.services)
      self.completion = nil
    }
  }
  
  // MARK: - Services
  
  private let concurrentServicesQueue: DispatchQueue = DispatchQueue(label: "\(MyBonjourManager.name).concurrentServicesQueue", attributes: .concurrent)
  var services: [MyNetService] = [] {
    didSet {
      self.delegate?.servicesDidUpdate(self.services)
    }
  }
  
  internal func clearServices() {
    self.services = []
    NotificationCenter.default.post(name: .bonjourDidClearServices, object: nil)
  }
  
  internal func add(service: MyNetService) {
    if !self.services.contains(service) {
      self.services.append(service)
      NotificationCenter.default.post(name: .bonjourDidAddService, object: service)
      service.resolve(completedAddressResolution: {
        self.checkDiscoveryCompletion()
      })
    }
  }
  
  internal func remove(service: MyNetService) {
    if let index = self.services.index(of: service) {
      self.services.remove(at: index)
      NotificationCenter.default.post(name: .bonjourDidRemoveService, object: service)
    }
  }
  
  // MARK: - Start / Stop Discovery
  
  func startDiscovery(timeout: Double = 5.0, completion: @escaping (_ services: [MyNetService]) -> Void) {
    self.stopDiscovery()
    self.clearServices()
    self.serviceBrowsers = []
    self.completion = completion
    
    // Populate service browsers with existing service types
    let allServiceTypes = MyServiceType.fetchAll()
    for serviceType in allServiceTypes {
      let serviceBrowser = MyNetServiceBrowser(serviceType: serviceType, domain: "")
      serviceBrowser.delegate = self
      self.serviceBrowsers.append(serviceBrowser)
    }
    
    // Populate service browsers with user-created service types
    for publishedService in MyBonjourPublishManager.shared.publishedServices {
      if !MyServiceType.exists(serviceTypes: allServiceTypes, fullType: publishedService.serviceType.fullType) {
        let serviceBrowser = MyNetServiceBrowser(serviceType: publishedService.serviceType, domain: publishedService.service.domain)
        serviceBrowser.delegate = self
        self.serviceBrowsers.append(serviceBrowser)
      }
    }
    
    // Start the search for each service browser
    for serviceBrowser in self.serviceBrowsers {
      serviceBrowser.startSearch()
    }
    
    // Establish timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
      
      guard let strongSelf = self else {
        return
      }
      
      strongSelf.completion?(strongSelf.services)
      strongSelf.completion = nil
      strongSelf.stopDiscovery()
    }
  }
  
  func stopDiscovery() {
    for serviceBrowser in self.serviceBrowsers {
      serviceBrowser.stopSearch()
    }
  }
}

// MARK: - MyNetServiceBrowserDelegate

extension MyBonjourManager : MyNetServiceBrowserDelegate {
  
  func myNetServiceBrowserDidChangeState(_ browser: MyNetServiceBrowser, state: MyNetServiceBrowserState) {
    self.checkDiscoveryCompletion()
  }
  
  func myNetServiceBrowser(_ browser: MyNetServiceBrowser, didFind service: MyNetService) {
    self.add(service: service)
  }
  
  func myNetServiceBrowser(_ browser: MyNetServiceBrowser, didRemove service: MyNetService) {
    self.remove(service: service)
  }
  
}
