//
//  NetService+InternetAddress.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/13/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import Foundation

// MARK: - NetService & InternetAddress

public extension NetService {

    /// Returns an array of `InternetAddress` associated with this `NetService`
    func parseInternetAddresses() -> [InternetAddress] {
        let addresses = self.addresses ?? []
        return addresses.compactMap { addressData in
            let nsData = addressData as NSData
            var inetAddress = sockaddr_in()
            nsData.getBytes(&inetAddress, length: MemoryLayout<sockaddr_in>.size)
            if inetAddress.sin_family == __uint8_t(AF_INET) {

                // IPv4
                if let ip = String(cString: inet_ntoa(inetAddress.sin_addr), encoding: .ascii) {
                    let port = inetAddress.sin_port.bigEndian
                    return InternetAddress(
                        ip: ip,
                        port: Int(port),
                        protocol: .v4
                    )
                }

            } else if inetAddress.sin_family == __uint8_t(AF_INET6) {

                // IPv6
                var inetAddress6 = sockaddr_in6()
                nsData.getBytes(&inetAddress6, length: MemoryLayout<sockaddr_in6>.size)
                let ipStringBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
                var addr = inetAddress6.sin6_addr
                if let ipString = inet_ntop(Int32(inetAddress6.sin6_family), &addr, ipStringBuffer, __uint32_t(INET6_ADDRSTRLEN)), let ip = String(cString: ipString, encoding: .ascii) {
                    let port = inetAddress6.sin6_port.bigEndian
                    return InternetAddress(
                        ip: ip,
                        port: Int(port),
                        protocol: .v6
                    )
                }
            }
            return nil
        }
    }
}
