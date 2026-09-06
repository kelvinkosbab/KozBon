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
    /// Wrapped in ``RefreshScanAction`` rather than stored as a bare
    /// closure so SwiftUI can compare it — see that type.
    @Entry var refreshScan: RefreshScanAction?
}
