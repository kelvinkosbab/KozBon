//
//  EmptyStateOverlayView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/19/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - EmptyStateOverlayView

struct EmptyStateOverlayView : View {
    
    let image: Image?
    let title: String
    
    var body: some View {
        VStack(spacing: Spacing.base) {
            if let image {
                image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, height: 100)
            }
            Text(self.title)
                .headingBoldStyle()
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview

struct EmptyStateOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateOverlayView(
            image: nil,
            title: "Some title saying something"
        )
        
        EmptyStateOverlayView(
            image: Image.bluetoothCapsuleFill,
            title: "Some title saying something"
        )
    }
}
