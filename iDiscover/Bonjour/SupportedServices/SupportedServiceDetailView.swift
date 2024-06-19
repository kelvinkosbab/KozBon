//
//  SupportedServiceDetailView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/18/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - SupportedServiceDetailView

struct SupportedServiceDetailView: View {

    let serviceType: BonjourServiceType

    init(serviceType: BonjourServiceType) {
        self.serviceType = serviceType
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: serviceType.imageSystemName)
                        .font(.system(.title3).bold())

                    VStack(alignment: .leading) {
                        Text(verbatim: serviceType.name)
                            .font(.system(.headline).bold())

                        Text(verbatim: serviceType.fullType)
                            .font(.system(.caption).bold())
                    }
                }
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 25)
                .background(.secondary)
                .clipShape(.capsule)
                .listRowBackground(Color(.clear))
                .frame(maxWidth: .infinity)
            }

            Section {
                TitleDetailStackView(
                    title: "Name",
                    detail: serviceType.name
                )
                TitleDetailStackView(
                    title: "Type",
                    detail: serviceType.type
                )
                TitleDetailStackView(
                    title: "Transport layer",
                    detail: serviceType.transportLayer.string
                )
                TitleDetailStackView(
                    title: "Full type",
                    detail: serviceType.fullType
                )
            }
        }
    }
}
