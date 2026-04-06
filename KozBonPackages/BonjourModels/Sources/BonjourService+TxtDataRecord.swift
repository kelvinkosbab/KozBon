//
//  BonjourService+TxtDataRecord.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - TxtDataRecord

extension BonjourService {
    public struct TxtDataRecord: Equatable, Comparable {
        public let key: String
        public let value: String

        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }

        public static func == (lhs: TxtDataRecord, rhs: TxtDataRecord) -> Bool {
            lhs.key == rhs.key
        }

        public static func < (lhs: TxtDataRecord, rhs: TxtDataRecord) -> Bool {
            lhs.key < rhs.key
        }
    }
}
