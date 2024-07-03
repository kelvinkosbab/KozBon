//
//  TitleDetailStackView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/14/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - TitleDetailStackView

struct TitleDetailChevronView: View {

    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(self.title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(self.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image.chevronRight
                .foregroundColor(.kozBonBlue)
        }
    }
}

// MARK: - Preview

#Preview {
    TitleDetailChevronView(title: "title", detail: "detail")
}
