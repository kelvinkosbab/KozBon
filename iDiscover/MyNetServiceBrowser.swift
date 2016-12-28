//
//  MyNetServiceBrowser.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

protocol MyNetServiceBrowserDelegate {
  func myNetServiceBrowserDidChangeState(_ browser: MyNetServiceBrowser, state: MyNetServiceBrowserState)
  func myNetServiceBrowser(_ browser: MyNetServiceBrowser, didFind service: MyNetService)
  func myNetServiceBrowser(_ browser: MyNetServiceBrowser, didRemove service: MyNetService)
}

class MyNetServiceBrowser: NSObject, NetServiceBrowserDelegate {
  
  // Equatable
  
  static func == (lhs: MyNetServiceBrowser, rhs: MyNetServiceBrowser) -> Bool {
    return lhs.serviceType.type == rhs.serviceType.type && lhs.domain == rhs.domain
  }
  
  // MARK: - Properties and Init
  
  var delegate: MyNetServiceBrowserDelegate? = nil
  
  private let serviceBrowser: NetServiceBrowser
  let serviceType: MyServiceType
  let domain: String
  
  var state: MyNetServiceBrowserState = .stopped {
    didSet {
      self.delegate?.myNetServiceBrowserDidChangeState(self, state: self.state)
    }
  }
  
  init(serviceType: MyServiceType, domain: String = "local.") {
    self.serviceType = serviceType
    self.domain = domain
    self.serviceBrowser = NetServiceBrowser()
    super.init()
    self.serviceBrowser.delegate = self
  }
  
  // MARK: - Start / Stop
  
  func startSearch(timeout: Double = 2.0) {
    self.stopSearch()
    self.serviceBrowser.searchForServices(ofType: self.serviceType.netServiceType, inDomain: self.domain)
    
    DispatchQueue.main.asyncAfter(after: timeout) { 
      self.serviceBrowser.stop()
    }
  }
  
  func stopSearch() {
    self.serviceBrowser.stop()
  }
  
  // MARK: - NetServiceBrowserDelegate
  
  func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
    self.state = .searching
  }
  
  func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
    self.state = .stopped
  }
  
  func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
    print("\(self.className) : Did not search for type \(self.serviceType.netServiceType) and domain \(self.domain) with error \(errorDict)")
    self.state = .stopped
  }
  
  func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    print("\(self.className) : Did find service \(service)")
    self.delegate?.myNetServiceBrowser(self, didFind: MyNetService(service: service, serviceType: self.serviceType))
    
    if !moreComing {
      browser.stop()
    }
  }
  
  func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    print("\(self.className) : Did remove service \(service)")
    self.delegate?.myNetServiceBrowser(self, didRemove: MyNetService(service: service, serviceType: self.serviceType))
    
    if !moreComing {
      browser.stop()
    }
  }
}
