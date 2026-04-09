//
//  AppFocusedValues.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - AppFocusedValues

public extension FocusedValues {
    @Entry var isBroadcastServicePresented: Binding<Bool>?
    @Entry var isCreateServiceTypePresented: Binding<Bool>?
    @Entry var refreshScan: (() -> Void)?
}
