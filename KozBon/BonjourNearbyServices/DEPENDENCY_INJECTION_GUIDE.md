# Dependency Injection Implementation Guide

## Overview

This guide documents the dependency injection (DI) system implemented for the KozBon application. The implementation follows modern Swift and SwiftUI patterns to make your code more testable, maintainable, and flexible.

## What Was Implemented

### 1. Core Infrastructure

#### `DependencyContainer.swift`
A central container that manages all application dependencies. It uses SwiftUI's `@Observable` macro for reactive updates and integrates with the `@Environment` system.

**Key features:**
- Singleton-free architecture (dependencies are injected, not accessed globally)
- Environment-based injection for easy access in views
- Support for test doubles through protocol abstraction

#### Protocol Abstractions

**`BonjourServiceScannerProtocol.swift`**
- Defines the interface for scanning Bonjour services
- Allows `BonjourServiceScanner` to be swapped with test implementations

**`BonjourPublishManagerProtocol.swift`**
- Defines the interface for publishing Bonjour services
- Enables testing without actual network operations

### 2. Refactored Components

#### `AppCore.swift`
Updated to create and inject a `DependencyContainer` into the entire view hierarchy:
```swift
@State private var dependencies = DependencyContainer()

// ... later in body
.environment(\.dependencies, dependencies)
```

#### `BonjourServicesViewModel.swift`
Refactored to accept dependencies through initializer injection:
```swift
init(serviceScanner: BonjourServiceScannerProtocol = BonjourServiceScanner.shared)
```

This maintains backward compatibility (defaults to shared instance) while enabling dependency injection for tests.

#### `BonjourScanForServicesView.swift`
Updated to support optional dependency injection through its initializer.

### 3. Testing Infrastructure

#### `MockDependencies.swift`
Contains mock implementations for testing:

**`MockBonjourServiceScanner`**
- Tracks method calls (start/stop scan)
- Simulates service discovery events
- Configurable state for different test scenarios

**`MockBonjourPublishManager`**
- Tracks publish/unpublish operations
- Simulates success/failure scenarios
- Maintains test state

#### `BonjourServicesViewModelTests.swift`
Example test suite demonstrating:
- Unit testing with injected dependencies
- Verifying behavior without network calls
- Testing sorting and filtering logic
- Simulating service discovery events

### 4. Documentation

#### `DependencyInjectionExamples.swift`
Comprehensive guide with code examples showing:
- Direct injection pattern for simple views
- ViewModel injection patterns
- Factory patterns for complex scenarios
- Using `@Observable` vs `ObservableObject`
- Testing with mock dependencies
- SwiftUI preview configurations

## How to Use

### In Production Code

#### Pattern 1: Direct Environment Access
For simple views without ViewModels:

```swift
struct MyView: View {
    @Environment(\.dependencies) private var dependencies
    
    var body: some View {
        Button("Start Scan") {
            dependencies.bonjourServiceScanner.startScan()
        }
    }
}
```

#### Pattern 2: ViewModel with Injected Dependencies
For views with ViewModels:

```swift
// ViewModel
class MyViewModel: ObservableObject {
    private let scanner: BonjourServiceScannerProtocol
    
    init(scanner: BonjourServiceScannerProtocol = BonjourServiceScanner.shared) {
        self.scanner = scanner
    }
}

// View
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(scanner: BonjourServiceScannerProtocol? = nil) {
        _viewModel = StateObject(wrappedValue: MyViewModel(
            scanner: scanner ?? BonjourServiceScanner.shared
        ))
    }
}
```

### In Tests

```swift
@Test("Example test with mocks")
func testWithMocks() async throws {
    // Create mock dependencies
    let mockScanner = MockBonjourServiceScanner()
    
    // Create view model with mock
    let viewModel = BonjourServicesViewModel(serviceScanner: mockScanner)
    
    // Perform action
    await MainActor.run {
        viewModel.load()
    }
    
    // Verify behavior
    #expect(mockScanner.startScanCallCount == 1)
}
```

### In SwiftUI Previews

```swift
#Preview {
    let mockScanner = MockBonjourServiceScanner()
    let dependencies = DependencyContainer.mock(scanner: mockScanner)
    
    return BonjourScanForServicesView(scanner: mockScanner)
        .environment(\.dependencies, dependencies)
}
```

## Benefits

### 1. Testability
- No need to test against real network services
- Fast, reliable tests that don't depend on external state
- Easy to simulate edge cases and error conditions

### 2. Flexibility
- Swap implementations for different environments (dev/staging/prod)
- Easy to add new dependencies
- Supports feature flags and A/B testing

### 3. Maintainability
- Clear dependency relationships
- Reduced coupling between components
- Easier to refactor and evolve

### 4. Debugging
- Can inject logging versions of services
- Easy to track dependency flow
- Better error isolation

## Migration Path

To continue migrating your codebase to dependency injection:

### Step 1: Identify Singletons
Look for patterns like:
- `SomeClass.shared`
- Static access to services
- Global state

### Step 2: Create Protocols
For each service, create a protocol defining its public interface:
```swift
protocol MyServiceProtocol {
    func doSomething()
}

extension MyService: MyServiceProtocol {}
```

### Step 3: Add to DependencyContainer
```swift
class DependencyContainer {
    let myService: MyServiceProtocol
    
    init() {
        self.myService = MyService.shared
    }
}
```

### Step 4: Update ViewModels
Change ViewModels to accept dependencies through their initializer:
```swift
init(myService: MyServiceProtocol = MyService.shared) {
    self.myService = myService
}
```

### Step 5: Update Views
Update views to pass dependencies when creating ViewModels.

### Step 6: Create Mocks
Create mock implementations for testing:
```swift
class MockMyService: MyServiceProtocol {
    var doSomethingCallCount = 0
    
    func doSomething() {
        doSomethingCallCount += 1
    }
}
```

## Best Practices

### 1. Protocol Design
- Keep protocols focused and cohesive
- Define only the methods that clients need
- Use protocol composition for complex requirements

### 2. Default Parameters
- Provide default implementations for convenience
- Makes migration easier (backward compatible)
- Production code can gradually adopt DI

### 3. Testing
- Create test-specific mock implementations
- Track method calls and state changes
- Use meaningful test names and documentation

### 4. Environment Usage
- Use `@Environment` for accessing dependencies in views
- Pass dependencies through initializers for ViewModels
- Avoid storing `@Environment` in @StateObject

### 5. Documentation
- Document what each dependency does
- Provide usage examples
- Keep migration guides up to date

## Common Patterns

### Lazy Dependencies
For expensive-to-create dependencies:
```swift
class DependencyContainer {
    private var _expensiveService: ExpensiveService?
    
    var expensiveService: ExpensiveServiceProtocol {
        if _expensiveService == nil {
            _expensiveService = ExpensiveService()
        }
        return _expensiveService!
    }
}
```

### Scoped Dependencies
For dependencies that need different lifetimes:
```swift
class DependencyContainer {
    func createSessionScoped() -> SessionDependencies {
        SessionDependencies(scanner: self.bonjourServiceScanner)
    }
}
```

### Conditional Dependencies
For feature flags or platform-specific code:
```swift
class DependencyContainer {
    let analytics: AnalyticsProtocol
    
    init() {
        #if DEBUG
        self.analytics = MockAnalytics()
        #else
        self.analytics = ProductionAnalytics()
        #endif
    }
}
```

## Next Steps

1. **Migrate Remaining Singletons**: Continue identifying and migrating other singleton services
2. **Add More Tests**: Write tests for existing ViewModels using the new mock infrastructure
3. **Document Dependencies**: Add documentation to each protocol explaining its purpose
4. **Review Protocols**: Ensure protocols aren't too broad or too narrow
5. **Consider Additional Patterns**: Look into more advanced DI patterns as needed (e.g., child containers, scopes)

## Resources

- `DependencyInjectionExamples.swift` - Comprehensive code examples
- `BonjourServicesViewModelTests.swift` - Test examples
- `MockDependencies.swift` - Mock implementations reference

## Questions?

Refer to the inline documentation in:
- `DependencyContainer.swift` for container usage
- `DependencyInjectionExamples.swift` for pattern examples
- Test files for testing patterns
