//
//  MyBonjourPublishManager.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

protocol MyBonjourPublishManagerDelegate: AnyObject {
    func publishedServicesUpdated(_ publishedServices: [BonjourService])
}

class MyBonjourPublishManager: NSObject {

    // MARK: - Singleton

    static let shared = MyBonjourPublishManager()

    private override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(self.serviceDidPublish(_:)), name: .netServiceDidPublish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.serviceDidUnPublish(_:)), name: .netServiceDidUnPublish, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Published Services

    private(set) var publishedServices: [BonjourService] = []

    private func add(publishedService service: BonjourService) {
        if !self.publishedServices.contains(service) {
            self.publishedServices.append(service)
            service.resolve()
        }
    }

    private func remove(publishedService service: BonjourService) {
        if let index = self.publishedServices.firstIndex(of: service) {
            self.publishedServices.remove(at: index)
        }
    }

    // MARK: - Notifications

    @objc
    private func serviceDidPublish(_ notification: Notification) {
        if let service = notification.object as? BonjourService {
            self.add(publishedService: service)
        }
    }

    @objc private func serviceDidUnPublish(_ notification: Notification) {
        if let service = notification.object as? BonjourService {
            self.remove(publishedService: service)
        }
    }

    // MARK: - Publishing

    func publish(
        name: String,
        type: String,
        port: Int,
        domain: String,
        transportLayer: TransportLayer,
        detail: String,
        success: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void
    ) {
        let serviceType = BonjourServiceType(name: name, type: type, transportLayer: transportLayer, detail: detail)
//        serviceType.savePersistentCopy()
        let netService = NetService(domain: domain, type: serviceType.fullType, name: name, port: Int32(port))
        let service = BonjourService(service: netService, serviceType: serviceType)
        self.publish(service: service, success: success, failure: failure)
    }
    
    func publish(
        name: String,
        type: String,
        port: Int,
        domain: String,
        transportLayer: TransportLayer,
        detail: String
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            publish(
                name: name,
                type: type,
                port: port,
                domain: domain,
                transportLayer: transportLayer,
                detail: detail
            ) {
                continuation.resume()
            } failure: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Publish

    func publish(
        service: BonjourService,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        service.publish(
            publishServiceSuccess: {
                self.add(publishedService: service)
                success()
            },
            publishServiceFailure: failure
        )
    }
    
    func publish(service: BonjourService) async throws {
        try await withCheckedThrowingContinuation { continuation in
            publish(service: service) {
                continuation.resume()
            } failure: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Un-Publish

    func unPublish(service: BonjourService, completion: (() -> Void)? = nil) {
        service.unPublish {
            self.remove(publishedService: service)
            completion?()
        }
    }
    
    func unPublish(service: BonjourService) async {
        await withCheckedContinuation { continuation in
            unPublish(service: service) {
                continuation.resume()
            }
        }
    }

    func unPublishAllServices(completion: (() -> Void)? = nil) {
        let dispatchGroup = DispatchGroup()
        for service in self.publishedServices {
            dispatchGroup.enter()
            self.unPublish(service: service) {
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion?()
        }
    }
    
    func unPublishAllServices() async {
        await withCheckedContinuation { continuation in
            unPublishAllServices {
                continuation.resume()
            }
        }
    }
}
