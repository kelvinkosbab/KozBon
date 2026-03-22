# KozBon

A multi-platform Apple app for discovering, browsing, and broadcasting Bonjour (mDNS/DNS-SD) network services.

## Features

- **Service Discovery** — Automatically scan and discover Bonjour services on your local network
- **Service Broadcasting** — Publish your own custom Bonjour services with configurable port, domain, and TXT records
- **120+ Built-in Service Types** — Pre-configured library of common service types (HTTP, SSH, AirPlay, and more)
- **Custom Service Types** — Create and persist your own service type definitions
- **Service Details** — View hostnames, IP addresses, transport layers, and TXT record metadata for any discovered service

## Platform Support

| Platform | Minimum Version | Key Features |
|----------|----------------|--------------|
| **iOS** | 18.6 | Pull-to-refresh scanning, context menus, pointer hover effects |
| **iPadOS** | 18.6 | Split-view navigation, drag & drop, trackpad hover effects |
| **macOS** | 15.6 | Menu bar commands, keyboard shortcuts, Settings window, multi-window support |
| **visionOS** | 2.0 | Glass UI styling, floating ornament controls, pointer hover effects |

## Architecture

- **Swift 6** with strict concurrency checking (`Sendable`, `@MainActor`, structured concurrency)
- **SwiftUI** with MVVM pattern across all platforms
- **NavigationSplitView** for adaptive list-detail layouts on iPad and Mac
- **Core Data** for persistent custom service type storage
- **Dependency Injection** via `DependencyContainer` using SwiftUI environment
- **Swift Testing** framework for unit tests (`@Test`, `@Suite`, `#expect`)
- **SwiftLint** for code style enforcement

## Build

```bash
# iOS Simulator
xcodebuild -scheme KozBon -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build

# macOS
xcodebuild -scheme KozBon -destination 'platform=macOS' build

# visionOS Simulator
xcodebuild -scheme KozBon -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# Run tests
xcodebuild test -scheme KozBon -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'
```

## Resources

- [TCP and UDP ports used by Apple software products](https://support.apple.com/en-gb/HT202944)
- [Service Name and Transport Protocol Port Number Registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)

## License

Copyright © 2016-present Kozinga. All rights reserved.
