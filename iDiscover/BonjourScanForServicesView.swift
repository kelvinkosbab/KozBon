//
//  BonjourScanForServicesView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - BonjourScanForServicesView

struct BonjourScanForServicesView : View {
    
    var body: some View {
        List {
            Text("BonjourScanForServicesView")
                .headingStyle()
            
            Text("more text")
        }
        .navigationTitle(NSLocalizedString(
            "Bonjour Services",
            comment: "Bonjour Services title"
        ))
        .navigationBarTitleDisplayMode(.inline)
    }
}
