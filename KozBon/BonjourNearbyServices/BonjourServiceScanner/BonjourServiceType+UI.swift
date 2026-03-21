//
//  BonjourServiceType+UI.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

extension BonjourServiceType {
    var imageSystemName: String {
        switch name.lowercased() {
        case "airplay",
            "airplay 2 undocumented":
            "airplayvideo"

        case "bonjour sleep proxy":
            "bonjour"

        case "remote audio output protocol (raop)":
            "hifispeaker.fill"

        case "workgroup manager":
            "squares.leading.rectangle"

        case "apple mobile device protocol v2":
            "platter.2.filled.iphone"

        case "apple tv",
            "apple tv (2nd generation)",
            "apple tv (3rd generation)",
            "apple tv (4th generation)",
            "apple tv pairing",
            "apple tv discovery of itunes":
            "appletv"

        case "apple tv media remote":
            "appletvremote.gen4.fill"

        case "mediaremotetv":
            "av.remote"

        case "remote login",
            "secure shell (ssh)",
            "secure sockets layer (ssl, or https)":
            "greaterthan.square"

        case "apple homekit",
            "homekit accessory protocol (hap)":
            "homekit"

        default:
            "wifi"
        }
    }
}
