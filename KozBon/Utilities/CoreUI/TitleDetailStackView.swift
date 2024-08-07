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

public struct TitleDetailStackView<Trailing>: View where Trailing: View {

    let title: String
    let detail: String
    let trailing: (() -> Trailing)?

    public init(
        title: String,
        detail: String,
        trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.detail = detail
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(
                alignment: .leading,
                spacing: Spacing.small
            ) {
                Text(self.title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(self.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            trailing?()
        }
    }
}

public extension TitleDetailStackView where Trailing == EmptyView {
    init(
        title: String,
        detail: String
    ) {
        self.title = title
        self.detail = detail
        self.trailing = nil
    }
}

// MARK: - Preview

struct BonjourServiceCardView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TitleDetailStackView(
                title: "title",
                detail: "detail"
            )
        }
    }
}
