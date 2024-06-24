//
//  BonjourService+TxtDataRecord.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/24/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import Foundation

// MARK: - TxtDataRecord

extension BonjourService {
    class TxtDataRecord: Equatable, Comparable {
        let key: String
        let value: String

        init(
            key: String,
            value: String
        ) {
            self.key = key
            self.value = value
        }

        static func == (lhs: TxtDataRecord, rhs: TxtDataRecord) -> Bool {
            lhs.key == rhs.key
        }

        static func < (lhs: TxtDataRecord, rhs: TxtDataRecord) -> Bool {
            lhs.key < rhs.key
        }
    }
}
