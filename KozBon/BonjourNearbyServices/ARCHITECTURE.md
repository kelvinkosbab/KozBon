# Dependency Injection Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AppCore.swift                           │
│                                                                 │
│  @main struct AppCore: App {                                   │
│      @State private var dependencies = DependencyContainer()    │
│                                                                 │
│      var body: some Scene {                                    │
│          WindowGroup {                                         │
│              TabView { ... }                                   │
│                  .environment(\.dependencies, dependencies)     │
│          }                                                     │
│      }                                                         │
│  }                                                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Injects DependencyContainer via Environment
                             │
            ┌────────────────┴────────────────┐
            │                                 │
            ▼                                 ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   View Layer            │     │   View Layer            │
│   (SwiftUI Views)       │     │   (SwiftUI Views)       │
│                         │     │                         │
│ @Environment(\.deps)    │     │ @Environment(\.deps)    │
│ private var deps        │     │ private var deps        │
└────────┬────────────────┘     └────────┬────────────────┘
         │                               │
         │ Creates ViewModels            │ Creates ViewModels
         │ with dependencies             │ with dependencies
         │                               │
         ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   ViewModel Layer       │     │   ViewModel Layer       │
│   (ObservableObject)    │     │   (ObservableObject)    │
│                         │     │                         │
│ class ViewModel {       │     │ class ViewModel {       │
│   let scanner: Protocol │     │   let service: Protocol │
│                         │     │                         │
│   init(scanner) { ... } │     │   init(service) { ... } │
│ }                       │     │ }                       │
└────────┬────────────────┘     └────────┬────────────────┘
         │                               │
         │ Uses protocol references      │ Uses protocol references
         │                               │
         ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   Service Layer         │     │   Service Layer         │
│   (Business Logic)      │     │   (Business Logic)      │
│                         │     │                         │
│ Protocol definitions:   │     │ Real implementations:   │
│ - ScannerProtocol       │     │ - BonjourScanner        │
│ - PublisherProtocol     │     │ - PublishManager        │
└─────────────────────────┘     └─────────────────────────┘
```

## Dependency Flow

### Production Flow
```
App Start
   │
   ├─> Create DependencyContainer
   │      │
   │      ├─> Real BonjourServiceScanner
   │      └─> Real MyBonjourPublishManager
   │
   ├─> Inject via Environment
   │
   ├─> View accesses dependencies
   │
   ├─> View creates ViewModel with dependencies
   │
   └─> ViewModel uses services via protocols
```

### Testing Flow
```
Test Start
   │
   ├─> Create Mock Services
   │      │
   │      ├─> MockBonjourServiceScanner
   │      └─> MockBonjourPublishManager
   │
   ├─> Create ViewModel with mocks
   │
   ├─> Execute test scenario
   │
   ├─> Verify mock was called correctly
   │
   └─> Assert expected behavior
```

## Component Relationships

```
┌──────────────────────────────────────────────────────────┐
│                  DependencyContainer                     │
│  ┌────────────────────────────────────────────────────┐ │
│  │                                                    │ │
│  │  let bonjourServiceScanner: Protocol               │ │
│  │  let bonjourPublishManager: Protocol               │ │
│  │                                                    │ │
│  │  init() {                                          │ │
│  │    scanner = BonjourServiceScanner.shared          │ │
│  │    publishManager = MyBonjourPublishManager.shared │ │
│  │  }                                                 │ │
│  │                                                    │ │
│  │  // Test constructor                               │ │
│  │  init(scanner: Protocol, publishManager: Protocol) │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────────┐       ┌─────────────────────┐
│     Protocols       │       │   Implementations   │
├─────────────────────┤       ├─────────────────────┤
│                     │       │                     │
│ Scanner Protocol    │◄──────│ BonjourScanner     │
│ - startScan()       │       │ (Production)        │
│ - stopScan()        │       │                     │
│ - isProcessing      │       │ MockScanner         │
│ - delegate          │◄──────│ (Testing)           │
│                     │       │                     │
├─────────────────────┤       ├─────────────────────┤
│                     │       │                     │
│ Publisher Protocol  │◄──────│ PublishManager      │
│ - publish()         │       │ (Production)        │
│ - unPublish()       │       │                     │
│ - publishedServices │◄──────│ MockPublishManager  │
│                     │       │ (Testing)           │
└─────────────────────┘       └─────────────────────┘
```

## Data Flow Example

### Scenario: User taps "Scan" button

```
User Action
   │
   ▼
┌─────────────────────────────────────────┐
│ BonjourScanForServicesView              │
│                                         │
│ Button("Scan") {                        │
│   viewModel.load() ─────────────────┐   │
│ }                                   │   │
└─────────────────────────────────────┼───┘
                                      │
                                      ▼
┌─────────────────────────────────────────┐
│ BonjourServicesViewModel                │
│                                         │
│ func load() {                           │
│   scanner.startScan() ──────────────┐   │
│ }                                   │   │
└─────────────────────────────────────┼───┘
                                      │
                                      ▼
┌─────────────────────────────────────────┐
│ BonjourServiceScannerProtocol           │
│ (Implemented by real or mock)           │
│                                         │
│ func startScan() {                      │
│   // Production: Start actual scan      │
│   // Test: Record call + simulate       │
│ }                                       │
└─────────────────────────────────────────┘
```

## File Organization

```
YourProject/
├── App/
│   └── AppCore.swift ✓ (Modified - Added DI)
│
├── Views/
│   ├── BonjourScanForServicesView.swift ✓ (Modified - Added DI)
│   ├── SupportedServicesView.swift
│   └── ...
│
├── ViewModels/
│   ├── BonjourServicesViewModel.swift ✓ (Modified - Added DI)
│   └── ...
│
├── Services/
│   ├── BonjourServiceScanner.swift
│   ├── MyBonjourPublishManager.swift
│   └── ...
│
├── DependencyInjection/ ⭐ NEW!
│   ├── Core/
│   │   ├── DependencyContainer.swift ⭐
│   │   ├── BonjourServiceScannerProtocol.swift ⭐
│   │   └── BonjourPublishManagerProtocol.swift ⭐
│   │
│   ├── Mocks/
│   │   └── MockDependencies.swift ⭐
│   │
│   ├── Examples/
│   │   ├── DependencyInjectionExamples.swift ⭐
│   │   └── PreviewDependencies.swift ⭐
│   │
│   └── Documentation/
│       ├── DEPENDENCY_INJECTION_GUIDE.md ⭐
│       ├── QUICK_START.md ⭐
│       └── ARCHITECTURE.md ⭐ (this file)
│
└── Tests/
    └── BonjourServicesViewModelTests.swift ⭐
```

## Protocol Hierarchy

```
┌─────────────────────────────────────────────────────┐
│             Service Protocols                       │
│  (Define contracts for all services)                │
└─────────────────┬───────────────────────────────────┘
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
┌──────────────────┐  ┌──────────────────┐
│ Scanner Protocol │  │Publisher Protocol│
├──────────────────┤  ├──────────────────┤
│ + startScan()    │  │ + publish()      │
│ + stopScan()     │  │ + unPublish()    │
│ + isProcessing   │  │ + publishedSvcs  │
│ + delegate       │  │                  │
└────────┬─────────┘  └────────┬─────────┘
         │                     │
    ┌────┴────┐           ┌────┴────┐
    │         │           │         │
    ▼         ▼           ▼         ▼
┌────────┐ ┌──────┐  ┌────────┐ ┌──────┐
│ Real   │ │ Mock │  │ Real   │ │ Mock │
│ Impl   │ │ Impl │  │ Impl   │ │ Impl │
└────────┘ └──────┘  └────────┘ └──────┘
```

## Testing Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Test Suite                        │
│  BonjourServicesViewModelTests                      │
└───────────────────────┬─────────────────────────────┘
                        │
                        │ Creates
                        │
                        ▼
        ┌──────────────────────────────┐
        │    Mock Dependency           │
        │    Container                 │
        └───────────┬──────────────────┘
                    │
        ┌───────────┴────────────┐
        │                        │
        ▼                        ▼
┌────────────────┐      ┌────────────────┐
│ MockScanner    │      │ MockPublisher  │
├────────────────┤      ├────────────────┤
│ - callCounts   │      │ - callCounts   │
│ - simulate()   │      │ - simulate()   │
│ - verify()     │      │ - verify()     │
└────────────────┘      └────────────────┘
        │                        │
        │                        │
        └────────┬───────────────┘
                 │
                 │ Injected into
                 │
                 ▼
        ┌────────────────┐
        │   ViewModel    │
        │  Under Test    │
        └────────────────┘
                 │
                 │ Execute
                 │
                 ▼
        ┌────────────────┐
        │  Verify Mock   │
        │  Was Called    │
        │  Correctly     │
        └────────────────┘
```

## Key Design Decisions

### 1. Protocol-Based Abstraction
**Why:** Enables swapping implementations without changing client code
```
Protocol (interface) ──┐
                       ├─> ViewModel uses protocol
Real Implementation ───┤
Mock Implementation ───┘
```

### 2. Environment-Based Injection
**Why:** Natural fit with SwiftUI's data flow
```
App creates container
   → Injects via .environment()
      → Views access via @Environment
         → Pass to ViewModels
```

### 3. Default Parameters
**Why:** Backward compatibility during migration
```swift
init(scanner: ScannerProtocol = RealScanner.shared)
// Old code: init() works ✓
// New code: init(scanner: mockScanner) works ✓
```

### 4. Separate Mock Implementations
**Why:** Clear separation of test code from production
```
Production/
   └── Services/
       └── RealImplementations.swift

Test/
   └── Mocks/
       └── MockImplementations.swift
```

## Migration Strategy

```
Phase 1: Foundation
   ├─> Create protocols
   ├─> Create DependencyContainer
   └─> Setup Environment injection

Phase 2: Core Services  ← YOU ARE HERE
   ├─> Migrate BonjourServiceScanner ✓
   ├─> Migrate MyBonjourPublishManager ✓
   └─> Update key ViewModels ✓

Phase 3: Expand
   ├─> Migrate remaining ViewModels
   ├─> Create more mocks
   └─> Write comprehensive tests

Phase 4: Optimize
   ├─> Remove singleton access
   ├─> Refine protocols
   └─> Add advanced DI patterns
```

## Benefits Visualization

```
Before DI:
┌──────────┐    uses    ┌──────────┐
│ViewModel │──────────> │Singleton │
└──────────┘            └──────────┘
     │                       │
     └───────────────────────┘
         Hard dependency
         Cannot test independently


After DI:
┌──────────┐    uses    ┌──────────┐
│ViewModel │──────────> │ Protocol │
└──────────┘            └─────┬────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
              ┌──────────┐        ┌────────┐
              │   Real   │        │  Mock  │
              │   Impl   │        │  Impl  │
              └──────────┘        └────────┘
              Production          Testing
```

## Summary

This architecture provides:
- ✅ **Testability**: Easy to mock any dependency
- ✅ **Flexibility**: Swap implementations easily
- ✅ **Maintainability**: Clear dependency relationships
- ✅ **Scalability**: Easy to add new dependencies
- ✅ **Type Safety**: Compiler-enforced contracts
- ✅ **SwiftUI Integration**: Natural environment flow
