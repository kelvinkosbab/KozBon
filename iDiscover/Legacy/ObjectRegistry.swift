//
//  BonjourServiceRegistry.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/24/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

final class ObjectRegistry<T: Hashable> {

    private var registered: Set<T>
    private let queue: DispatchQueue

    init() {
        self.registered = Set()
        self.queue = DispatchQueue(label: "\(UUID().uuidString).ObjectRegistry")
    }

    func register(_ object: T) {
        self.queue.async { [weak self] in
            self?.registered.update(with: object)
        }
    }

    func deregister(_ object: T) {
        self.queue.async { [weak self] in
            self?.registered.remove(object)
        }
    }

    func fetchAll() -> Set<T> {
        self.queue.sync {
            self.registered
        }
    }

    func removeAll() {
        self.queue.sync {
            self.registered = Set()
        }
    }
}
