//
//  VerticallyCenteredLabelStyle.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/13/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - VerticallyCenteredLabelStyle

struct VerticallyCenteredLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.icon
            configuration.title
        }
    }
}
