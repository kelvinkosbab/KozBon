//
//  ChatOfflineBanner.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization

// MARK: - ChatOfflineBanner

/// Sits above the compose bar while a cloud model is selected and the
/// device has no internet connection. Sending is disabled for that
/// time; the banner says why and that local features still work.
///
/// Neutral rather than red: being offline isn't something the app got
/// wrong, and the banner disappears on its own when the connection
/// returns.
struct ChatOfflineBanner: View {

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: Iconography.wifiSlash)
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Connectivity.offlineTitle)
                    .font(.subheadline.weight(.semibold))
                Text(Strings.Connectivity.offlineCloudAI)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .platformGlassBackground(
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("chat_offline_banner")
    }
}

// MARK: - Preview

#Preview {
    ChatOfflineBanner()
        .padding()
}
