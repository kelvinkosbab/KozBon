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

class MyBonjourManager: NSObject, MyNetServiceBrowserDelegate {
  
  // MARK: - Singleton
  
  static let shared = MyBonjourManager()
  
  private override init() { super.init() }
  
  // MARK: - Properties
  
  var completion: ((_ services: [MyNetService]) -> Void)? = nil
  
  private var serviceBrowsers: [MyNetServiceBrowser] = []
  
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
  
  private var _services: [MyNetService] = []
  private let concurrentServicesQueue: DispatchQueue = DispatchQueue(label: "\(MyBonjourManager.name).concurrentServicesQueue", attributes: .concurrent)
  
  private var services: [MyNetService] {
    var copy: [MyNetService]!
    self.concurrentServicesQueue.sync {
      copy = self._services
    }
    return copy
  }
  
  private func clearServices() {
    self.concurrentServicesQueue.async(flags: .barrier, execute: { () -> Void in
      self._services = []
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: .bonjourDidClearServices, object: nil)
      }
    })
  }
  
  private func add(service: MyNetService) {
    self.concurrentServicesQueue.async(flags: .barrier, execute: { () -> Void in
      if !self._services.contains(service) {
        self._services.append(service)
        DispatchQueue.main.async {
          NotificationCenter.default.post(name: .bonjourDidAddService, object: service)
          service.resolve {
            self.checkDiscoveryCompletion()
          }
        }
      }
    })
  }
  
  private func remove(service: MyNetService) {
    self.concurrentServicesQueue.async(flags: .barrier, execute: { () -> Void in
      if let index = self._services.index(of: service) {
        self._services.remove(at: index)
        DispatchQueue.main.async {
          NotificationCenter.default.post(name: .bonjourDidRemoveService, object: service)
        }
      }
    })
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
      if !allServiceTypes.contains(publishedService.serviceType) {
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
    DispatchQueue.main.asyncAfter(after: timeout) {
      self.completion?(self.services)
      self.completion = nil
      self.stopDiscovery()
    }
  }
  
  func stopDiscovery() {
    for serviceBrowser in self.serviceBrowsers {
      serviceBrowser.stopSearch()
    }
    for service in self.services {
      service.stop()
    }
  }
  
  // MARK: - MyNetServiceBrowserDelegate
  
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
