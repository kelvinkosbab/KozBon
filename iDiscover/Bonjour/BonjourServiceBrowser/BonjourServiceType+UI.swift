//
//  BonjourServiceType+UI.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/13/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import Foundation

extension BonjourServiceType {
    var imageSystemName: String {
        switch name.lowercased() {
        case "airplay":
            "airplayvideo"

        case "bonjour sleep proxy":
            "bonjour"

        case "remote audio output protocol (raop)":
            "hifispeaker.fill"

        case "workgroup manager":
            "square.on.square"

        case "apple mobile device protocol v2":
            "platter.2.filled.iphone"

        default:
            "wifi"
        }
    }
}
