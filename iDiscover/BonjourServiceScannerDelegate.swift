//
//  BonjourServiceScannerDelegate.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/7/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceScannerDelegate

protocol BonjourServiceScannerDelegate : AnyObject {
    func didAdd(service: BonjourService)
    func didRemove(service: BonjourService)
    func didReset()
}
