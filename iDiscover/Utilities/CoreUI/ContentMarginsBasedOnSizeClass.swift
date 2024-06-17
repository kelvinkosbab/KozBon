//
//  ContentMarginsBasedOnSizeClass.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/17/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - ContentMarginsBasedOnSize

private struct ContentMarginsBasedOnSizeClass: ViewModifier {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            if #available(iOS 17.0, *), horizontalSizeClass == .regular {
                content
                    .contentMargins(
                        .horizontal,
                        geometry.size.width > 1000 ? 200 : geometry.size.width > 600 ? 150 : 0,
                        for: .scrollContent
                    )
            } else {
                content
            }
        }
    }
}

// MARK: - View Extensions

public extension View {
    func contentMarginsBasedOnSizeClass() -> some View {
        modifier(ContentMarginsBasedOnSizeClass())
    }
}
