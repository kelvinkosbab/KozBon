//
//  MyBonjourPublishManager.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

class MyBonjourPublishManager: NSObject {
  
  // MARK: - Singleton
  
  static let shared = MyBonjourPublishManager()
  
  private override init() { super.init() }
  
  // MARK: - Properties
  
  var publishedServices: [MyNetService] = []
  
  // MARK: - Publishing
  
  func publish(name: String, type: String, port: Int, domain: String, transportLayer: MyTransportLayer, detail: String? = nil, success: @escaping () -> Void, failure: @escaping () -> Void) {
    let netService = NetService(domain: domain, type: type, name: name, port: Int32(port))
    let serviceType = MyServiceType(name: name, type: type, transportLayer: transportLayer, detail: detail)
    let service = MyNetService(service: netService, serviceType: serviceType)
    self.publish(service: service, success: success, failure: failure)
  }
  
  func publish(service: MyNetService, success: @escaping () -> Void, failure: @escaping () -> Void) {
    service.publish(publishServiceSuccess: {
      self.publishedServices.append(service)
      success()
      
    }, publishServiceFailure: failure)
  }
  
  func stopAllServices() {
    for service in self.publishedServices {
      service.stop()
    }
  }
}
