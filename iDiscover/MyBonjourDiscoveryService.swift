//
//  MyBonjourDiscoveryService.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/24/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

class MyBonjourDiscoveryService: NSObject, MyNetServiceBrowserDelegate {
  
  // MARK: - Singleton
  
  static let shared = MyBonjourDiscoveryService()
  
  // MARK: - Properties
  
  var completion: ((_ services: [MyNetService]) -> Void)? = nil
  var didStartSearch: (() -> Void)? = nil
  
  private var state: MyNetServiceBrowserState = .stopped {
    didSet {
      if self.state.isSearching && oldValue.isStopped {
        self.didStartSearch?()
      } else if self.state.isStopped && oldValue.isSearching {
        print("\(self.className) : State is now \(self.state.string)")
        self.completion?(self.services)
      }
    }
  }
  
  var isSearching: Bool {
    return self.state.isSearching
  }
  
  var isStopped: Bool {
    return self.state.isStopped
  }
  
  private var serviceBrowsers: [MyNetServiceBrowser] = []
  private let concurrentServicesQueue: DispatchQueue = DispatchQueue(label: "MyBonjourDiscoveryService.concurrentServicesQueue", attributes: .concurrent)
  
  // MARK: - Init
  
  private override init() { super.init() }
  
  // MARK: - Services
  
  private var _services: [MyNetService] = []
  
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
    })
  }
  
  private func add(service: MyNetService) {
    self.concurrentServicesQueue.async(flags: .barrier, execute: { () -> Void in
      if !self._services.contains(service) {
        self._services.append(service)
      }
    })
  }
  
  private func remove(service: MyNetService) {
    self.concurrentServicesQueue.async(flags: .barrier, execute: { () -> Void in
      if let index = self._services.index(of: service) {
        self._services.remove(at: index)
      }
    })
  }
  
  // MARK: - Start / Stop Discovery
  
  func startDiscovery(serviceType: MyServiceType, completion: @escaping (_ services: [MyNetService]) -> Void, didStartSearch: (() -> Void)? = nil) {
    self.startDiscovery(serviceTypes: [ serviceType ], completion: completion, didStartSearch: didStartSearch)
  }
  
  func startDiscovery(serviceTypes: [MyServiceType]? = nil, completion: @escaping (_ services: [MyNetService]) -> Void, didStartSearch: (() -> Void)? = nil) {
    self.clearServices()
    self.serviceBrowsers = []
    self.completion = completion
    self.didStartSearch = didStartSearch
    
    // Populate service browsers
    for serviceType in serviceTypes ?? MyServiceType.allServiceTypes {
      let serviceBrowser = MyNetServiceBrowser(serviceType: serviceType, domain: "")
      serviceBrowser.delegate = self
      self.serviceBrowsers.append(serviceBrowser)
    }
    
    // Start the search for each service browser
    for serviceBrowser in self.serviceBrowsers {
      serviceBrowser.startSearch()
    }
  }
  
  func stopDiscovery() {
    for serviceBrowser in self.serviceBrowsers {
      serviceBrowser.stopSearch()
    }
  }
  
  // MARK: - MyNetServiceBrowserDelegate
  
  func myNetServiceBrowserDidChangeState(_ browser: MyNetServiceBrowser, state: MyNetServiceBrowserState) {
    
    // Calculate new state
    var isSearching: Bool = false
    for serviceBrowser in self.serviceBrowsers {
      if serviceBrowser.state.isSearching {
        isSearching = true
        break
      }
    }
    self.state = isSearching ? .searching : .stopped
  }
  
  func myNetServiceBrowser(_ browser: MyNetServiceBrowser, didFind service: MyNetService) {
    self.add(service: service)
  }
  
  func myNetServiceBrowser(_ browser: MyNetServiceBrowser, didRemove service: MyNetService) {
    self.remove(service: service)
  }
}
