//
//  RecentServiceEntities.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - RecentServiceEntities

/// The services the List action returned most recently.
///
/// Shortcuts looks an entity up by id when it passes one between steps
/// or shows a picker. Bonjour discoveries don't persist, so the lookup
/// can only succeed against the latest scan in this process.
public actor RecentServiceEntities {

    public static let shared = RecentServiceEntities()

    private var entities: [BonjourServiceEntity] = []

    public init() {}

    func replace(with entities: [BonjourServiceEntity]) {
        self.entities = entities
    }

    func entities(for identifiers: [BonjourServiceEntity.ID]) -> [BonjourServiceEntity] {
        let wanted = Set(identifiers)
        return entities.filter { wanted.contains($0.id) }
    }

    func all() -> [BonjourServiceEntity] {
        entities
    }
}
