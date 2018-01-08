//
//  MyNetServiceBrowser.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

protocol MyNetServiceBrowserDelegate : class{
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
  
  weak var delegate: MyNetServiceBrowserDelegate? = nil
  
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
  
  func startSearch(timeout: Double = 1.0) {
    self.stopSearch()
    self.serviceBrowser.searchForServices(ofType: self.serviceType.fullType, inDomain: self.domain)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
      self?.serviceBrowser.stop()
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
    Log.log("Did not search for type \(self.serviceType.fullType) and domain \(self.domain) with error \(errorDict)")
    self.state = .stopped
  }
  
  func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    Log.log("Did find service \(service)")
    let netService = MyNetService(service: service, serviceType: self.serviceType)
    self.delegate?.myNetServiceBrowser(self, didFind: netService)
    
    if !moreComing {
      browser.stop()
    }
  }
  
  func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    Log.log("Did remove service \(service)")
    let netService = MyNetService(service: service, serviceType: self.serviceType)
    self.delegate?.myNetServiceBrowser(self, didRemove: netService)
    
    if !moreComing {
      browser.stop()
    }
  }
}
