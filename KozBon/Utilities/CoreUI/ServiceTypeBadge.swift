//
//  ServiceTypeBadge.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 7/8/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - ServiceTypeBadge

struct ServiceTypeBadge: View {
    
    let serviceType: BonjourServiceType
    let style: Style
    
    var body: some View {
        HStack {
            Label(serviceType.name, systemImage: serviceType.imageSystemName)
                .modifier(LabelStyle(style: style))
                .padding(.vertical, 6)
                .padding(.horizontal)
        }
        .background(
            Color.kozBonBlue
                .opacity(0.4)
        )
        .clipShape(.capsule)
    }
    
    // MARK: - Style
    
    enum Style {
        case titleAndIcon
        case iconOnly
        case basedOnSizeClass
    }
    
    // MARK: - LabelStyle
    
    private struct LabelStyle: ViewModifier {
        
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
        let style: Style
        
        func body(content: Content) -> some View {
            switch style {
            case .titleAndIcon:
                content.labelStyle(.titleAndIcon)
                
            case .iconOnly:
                content.labelStyle(.iconOnly)
                
            case .basedOnSizeClass:
                if horizontalSizeClass == .regular {
                    content
                        .labelStyle(.titleAndIcon)
                } else {
                    content
                        .labelStyle(.iconOnly)
                }
            }
        }
    }
}
