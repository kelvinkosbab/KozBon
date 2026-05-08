//
//  BonjourService+TxtDataRecord.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - TxtDataRecord

extension BonjourService {

    /// A key-value pair extracted from a Bonjour service's TXT record.
    ///
    /// TXT records carry lightweight metadata published alongside a service advertisement.
    /// Each record consists of a unique key and a UTF-8 string value.
    public struct TxtDataRecord: Equatable, Comparable {

        /// The record key (e.g. `"path"`, `"txtvers"`).
        public let key: String

        /// The record value associated with ``key``.
        public let value: String

        /// Creates a new TXT data record.
        ///
        /// - Parameters:
        ///   - key: The record key.
        ///   - value: The record value.
        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }

        /// Two TXT data records are equal when they share the same ``key``,
        /// regardless of their ``value``.
        public static func == (lhs: TxtDataRecord, rhs: TxtDataRecord) -> Bool {
            lhs.key == rhs.key
        }

        /// Records are ordered alphabetically by ``key``.
        public static func < (lhs: TxtDataRecord, rhs: TxtDataRecord) -> Bool {
            lhs.key < rhs.key
        }
    }
}
