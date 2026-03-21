//
//  BonjourService+TxtDataRecord.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - TxtDataRecord

extension BonjourService {
    struct TxtDataRecord: Equatable, Comparable {
        let key: String
        let value: String

        static func == (lhs: TxtDataRecord, rhs: TxtDataRecord) -> Bool {
            lhs.key == rhs.key
        }

        static func < (lhs: TxtDataRecord, rhs: TxtDataRecord) -> Bool {
            lhs.key < rhs.key
        }
    }
}
