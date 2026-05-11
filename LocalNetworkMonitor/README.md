# LocalNetworkMonitor

A small, focused Swift package that detects whether the device is currently on a network interface that can carry **local-link traffic like Bonjour / mDNS / DNS-SD**. Wraps `Network.framework`'s `NWPathMonitor` behind a `@MainActor` delegate API and ships a synchronous mock for tests.

## Why

Anything that depends on local-link multicast — Bonjour browsing, AirPlay receiver discovery, Chromecast / DLNA scanning, mDNS-based LAN service catalogs — needs to know when the device can actually see the local network. Showing a generic "no devices found" empty state when the user is on cellular is a UX dead end; this package lets you tell them why.

The classification rule is simple:

> *On local network* ⇔ `path.status == .satisfied` **and** `path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet)`

Cellular alone is explicitly excluded because mobile carriers strip multicast DNS traffic, so even an otherwise-online iPhone on LTE/5G will discover exactly nothing.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/kelvinkosbab/LocalNetworkMonitor.git", from: "1.0.0")
]
```

Then add `LocalNetworkMonitor` to your target's dependencies.

## Usage

```swift
import LocalNetworkMonitor

@MainActor
@Observable
final class DiscoverViewModel: LocalNetworkMonitorDelegate {

    private let monitor: any LocalNetworkMonitorProtocol = LocalNetworkMonitor()

    private(set) var isOnLocalNetwork: Bool = true

    init() {
        monitor.delegate = self
        // Seed from the monitor's current value, then start.
        isOnLocalNetwork = monitor.isOnLocalNetwork
        monitor.start()
    }

    func localNetworkMonitor(didChangeIsOnLocalNetwork isOnLocalNetwork: Bool) {
        withAnimation {
            self.isOnLocalNetwork = isOnLocalNetwork
        }
    }
}
```

The monitor exposes a single observable bit: `isOnLocalNetwork`. It defaults to `true` optimistically so the UI doesn't flash a "no local network" state during the brief window before `NWPathMonitor`'s first update arrives after `start()`.

## Testing

Drop in the included mock to drive connectivity transitions synchronously, without involving the OS network stack:

```swift
import LocalNetworkMonitor

@Test("ViewModel shows banner when device leaves local network")
@MainActor
func showsBannerOffLocalNetwork() {
    let monitor = MockLocalNetworkMonitor(initialIsOnLocalNetwork: true)
    let viewModel = MyViewModel(monitor: monitor)

    monitor.isOnLocalNetwork = false  // fires delegate synchronously
    #expect(viewModel.showsNoNetworkBanner)
}
```

## API surface

| Type | Description |
|---|---|
| `LocalNetworkMonitor` | Production implementation backed by `NWPathMonitor`. |
| `MockLocalNetworkMonitor` | Synchronous mock for tests and SwiftUI previews. |
| `LocalNetworkMonitorProtocol` | The contract both implementations satisfy. Use this in your DI types. |
| `LocalNetworkMonitorDelegate` | One callback: `localNetworkMonitor(didChangeIsOnLocalNetwork:)`. |

All public types are `@MainActor` and `Sendable`. The implementation hops `NWPathMonitor` callbacks off its private dispatch queue onto the main actor before mutating state or notifying delegates, so consumers never see threading concerns.

## Platforms

- iOS 14.0+
- macOS 11.0+
- tvOS 14.0+
- watchOS 7.0+
- visionOS 1.0+

Swift 6 with strict concurrency enabled.

## License

Copyright © 2016–present Kozinga. All rights reserved.
