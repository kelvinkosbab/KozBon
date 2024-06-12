//
//  BarItem.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/21/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BarItem

protocol BarItem : Identifiable {
    var id: String { get }
    var titleString: String { get }
    var icon: Image { get }
    var content: AnyView { get }
    var destination: AnyView? { get }
    var isSelectable: Bool { get }
}
