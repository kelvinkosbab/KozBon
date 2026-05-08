//
//  VerticallyCenteredLabelStyle.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - VerticallyCenteredLabelStyle

/// A label style that arranges the icon and title horizontally with vertical center alignment.
public struct VerticallyCenteredLabelStyle: LabelStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.icon
            configuration.title
        }
    }
}
