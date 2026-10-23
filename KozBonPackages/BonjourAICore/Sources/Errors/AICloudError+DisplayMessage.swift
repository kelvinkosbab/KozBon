//
//  AICloudError+DisplayMessage.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourLocalization
import InternetConnectivity

// MARK: - AICloudError + Display Message

public extension AICloudError {

    /// The text a chat or Insights surface shows for a failed request.
    ///
    /// Connectivity failures get the localized "check your connection"
    /// message; ``errorDescription`` is English-only and meant for logs.
    /// Everything else keeps its existing description.
    static func displayMessage(for error: any Error) -> String {
        if (error as? AICloudError) == .networkUnavailable || ConnectivityFailure.isOffline(error) {
            return String(localized: Strings.Connectivity.requestFailed)
        }
        return error.localizedDescription
    }
}
