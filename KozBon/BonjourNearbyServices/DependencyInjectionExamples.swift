//
//  DependencyInjectionExamples.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

/*
 
 DEPENDENCY INJECTION GUIDE
 ==========================
 
 This file demonstrates different patterns for dependency injection in SwiftUI.
 
 ## Pattern 1: Direct Injection (Best for Views)
 
 For simple views that don't need ObservableObject ViewModels, inject dependencies
 directly through the environment:
 
 ```swift
 struct SimpleView: View {
     @Environment(\.dependencies) private var dependencies
     
     var body: some View {
         Button("Start Scan") {
             dependencies.bonjourServiceScanner.startScan()
         }
     }
 }
 ```
 
 ## Pattern 2: ViewModels with Initializer Injection
 
 For ViewModels, use initializer injection with a default parameter:
 
 ```swift
 class MyViewModel: ObservableObject {
     private let scanner: BonjourServiceScannerProtocol
     
     init(scanner: BonjourServiceScannerProtocol = BonjourServiceScanner.shared) {
         self.scanner = scanner
     }
 }
 ```
 
 ## Pattern 3: View with Injected ViewModel
 
 For views using ViewModels, there are two approaches:
 
 ### Approach A: Factory Function (Recommended)
 
 Create a factory function that constructs the view with dependencies:
 
 ```swift
 struct MyView: View {
     @StateObject private var viewModel: MyViewModel
     
     // Default initializer uses singleton
     init() {
         _viewModel = StateObject(wrappedValue: MyViewModel())
     }
     
     // Factory function for dependency injection
     static func create(dependencies: DependencyContainer) -> MyView {
         MyView(viewModel: MyViewModel(scanner: dependencies.bonjourServiceScanner))
     }
     
     // Private initializer for factory
     private init(viewModel: MyViewModel) {
         _viewModel = StateObject(wrappedValue: viewModel)
     }
     
     var body: some View {
         // Your view code
     }
 }
 ```
 
 Usage in parent view:
 ```swift
 @Environment(\.dependencies) private var dependencies
 
 var body: some View {
     NavigationStack {
         MyView.create(dependencies: dependencies)
     }
 }
 ```
 
 ### Approach B: Optional Parameter (Simpler)
 
 Allow optional dependency injection through the view's initializer:
 
 ```swift
 struct MyView: View {
     @StateObject private var viewModel: MyViewModel
     
     init(scanner: BonjourServiceScannerProtocol? = nil) {
         _viewModel = StateObject(wrappedValue: MyViewModel(
             scanner: scanner ?? BonjourServiceScanner.shared
         ))
     }
     
     var body: some View {
         // Your view code
     }
 }
 ```
 
 Usage:
 ```swift
 @Environment(\.dependencies) private var dependencies
 
 var body: some View {
     NavigationStack {
         MyView(scanner: dependencies.bonjourServiceScanner)
     }
 }
 ```
 
 ## Pattern 4: Using @Observable (iOS 17+)
 
 For newer projects using @Observable instead of ObservableObject:
 
 ```swift
 @Observable
 class MyViewModel {
     private let scanner: BonjourServiceScannerProtocol
     
     init(scanner: BonjourServiceScannerProtocol) {
         self.scanner = scanner
     }
 }
 
 struct MyView: View {
     @Environment(\.dependencies) private var dependencies
     @State private var viewModel: MyViewModel?
     
     var body: some View {
         if let viewModel {
             // Your view code using viewModel
         }
         .task {
             if viewModel == nil {
                 viewModel = MyViewModel(scanner: dependencies.bonjourServiceScanner)
             }
         }
     }
 }
 ```
 
 ## Testing with Mock Dependencies
 
 Create mock implementations for testing:
 
 ```swift
 class MockBonjourServiceScanner: BonjourServiceScannerProtocol {
     weak var delegate: BonjourServiceScannerDelegate?
     var isProcessing: Bool = false
     var startScanCalled = false
     
     func startScan() {
         startScanCalled = true
     }
     
     func stopScan() {}
 }
 
 // In your tests or previews:
 let mockScanner = MockBonjourServiceScanner()
 let testDependencies = DependencyContainer(
     bonjourServiceScanner: mockScanner,
     bonjourPublishManager: mockPublishManager
 )
 
 MyView(scanner: mockScanner)
 ```
 
 ## SwiftUI Previews with Dependencies
 
 ```swift
 #Preview {
     let mockScanner = MockBonjourServiceScanner()
     let dependencies = DependencyContainer(
         bonjourServiceScanner: mockScanner,
         bonjourPublishManager: MockBonjourPublishManager()
     )
     
     return MyView(scanner: mockScanner)
         .environment(\.dependencies, dependencies)
 }
 ```
 
 */

// Example implementations for reference:

// MARK: - Example View with Direct Injection

struct ExampleDirectInjectionView: View {
    @Environment(\.dependencies) private var dependencies

    var body: some View {
        Button("Start Scan") {
            dependencies.bonjourServiceScanner.startScan()
        }
    }
}

// MARK: - Example ViewModel with Injection

@MainActor
@Observable
final class ExampleViewModel {
    var isScanning = false

    private let scanner: any BonjourServiceScannerProtocol
    private let publishManager: any BonjourPublishManagerProtocol

    init(
        scanner: any BonjourServiceScannerProtocol = BonjourServiceScanner.shared,
        publishManager: any BonjourPublishManagerProtocol = MyBonjourPublishManager.shared
    ) {
        self.scanner = scanner
        self.publishManager = publishManager
    }

    func startScanning() {
        isScanning = true
        scanner.startScan()
    }

    func stopScanning() {
        isScanning = false
        scanner.stopScan()
    }
}

// MARK: - Example View with ViewModel Injection

struct ExampleViewModelInjectionView: View {
    @State private var viewModel: ExampleViewModel

    // Default initializer
    init() {
        _viewModel = State(initialValue: ExampleViewModel())
    }

    // Injection initializer for testing/customization
    init(scanner: BonjourServiceScannerProtocol, publishManager: BonjourPublishManagerProtocol) {
        _viewModel = State(initialValue: ExampleViewModel(
            scanner: scanner,
            publishManager: publishManager
        ))
    }

    var body: some View {
        VStack {
            Text(viewModel.isScanning ? "Scanning..." : "Not scanning")

            Button("Toggle Scan") {
                if viewModel.isScanning {
                    viewModel.stopScanning()
                } else {
                    viewModel.startScanning()
                }
            }
        }
    }
}
