//
//  PreviewDependencies.swift
//  KozBon
//
//  Created by Dependency Injection Implementation
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Preview Helpers

extension DependencyContainer {
    
    /// Creates a dependency container configured for SwiftUI previews
    /// with sensible defaults and mock data
    @MainActor
    static func preview(
        withMockData: Bool = true,
        simulateScanning: Bool = false
    ) -> DependencyContainer {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        
        // Configure mock behavior for previews
        if simulateScanning {
            scanner.isProcessing = true
        }
        
        if withMockData {
            // Add some sample services for preview
            Task { @MainActor in
                let sampleServiceType = BonjourServiceType(
                    name: "HTTP",
                    type: "http",
                    transportLayer: .tcp,
                    detail: "Web Server"
                )
                let sampleService = BonjourService(
                    service: NetService(
                        domain: "local.",
                        type: sampleServiceType.fullType,
                        name: "Sample Device",
                        port: 8080
                    ),
                    serviceType: sampleServiceType
                )
                try? await publishManager.publish(service: sampleService)
            }
        }
        
        return DependencyContainer(
            bonjourServiceScanner: scanner,
            bonjourPublishManager: publishManager
        )
    }
}

// MARK: - Preview Examples

// Example 1: Basic preview with mock dependencies
#Preview("Basic View with Mocks") {
    let mockScanner = MockBonjourServiceScanner()
    let dependencies = DependencyContainer.mock(scanner: mockScanner)
    
    return ExampleDirectInjectionView()
        .environment(\.dependencies, dependencies)
}

// Example 2: Preview with simulated scanning
#Preview("Scanning State") {
    let dependencies = DependencyContainer.preview(simulateScanning: true)
    
    return ExampleViewModelInjectionView()
        .environment(\.dependencies, dependencies)
}

// Example 3: Preview with mock data
#Preview("With Mock Services") {
    let dependencies = DependencyContainer.preview(withMockData: true)
    
    return ExampleViewModelInjectionView()
        .environment(\.dependencies, dependencies)
}

// Example 4: Multiple preview configurations
#Preview("Different States", traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        // Empty state
        Group {
            let emptyDeps = DependencyContainer.mock()
            ExampleDirectInjectionView()
                .environment(\.dependencies, emptyDeps)
        }
        
        Divider()
        
        // Scanning state
        Group {
            let scanningDeps = DependencyContainer.preview(simulateScanning: true)
            ExampleDirectInjectionView()
                .environment(\.dependencies, scanningDeps)
        }
        
        Divider()
        
        // With data
        Group {
            let dataDeps = DependencyContainer.preview(withMockData: true)
            ExampleDirectInjectionView()
                .environment(\.dependencies, dataDeps)
        }
    }
    .padding()
}

// MARK: - Preview with Custom Mock Behavior

#Preview("Custom Mock Behavior") {
    // Create custom mocks with specific behavior
    let mockScanner = MockBonjourServiceScanner()
    let mockPublishManager = MockBonjourPublishManager()
    
    // Configure custom behavior
    mockScanner.isProcessing = true
    mockPublishManager.shouldSucceed = false
    mockPublishManager.errorToThrow = MockError.networkError
    
    let dependencies = DependencyContainer(
        bonjourServiceScanner: mockScanner,
        bonjourPublishManager: mockPublishManager
    )
    
    return ExampleViewModelInjectionView()
        .environment(\.dependencies, dependencies)
}

// MARK: - ViewModel Preview Example

#Preview("View Model Based View") {
    // Create mock dependencies
    let mockScanner = MockBonjourServiceScanner()
    
    // Configure mock to simulate finding services
    Task {
        // Simulate delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let serviceType = BonjourServiceType(
            name: "Test Service",
            type: "test",
            transportLayer: .tcp,
            detail: "Test"
        )
        let service = BonjourService(
            service: NetService(domain: "", type: serviceType.fullType, name: "Preview Device", port: 9999),
            serviceType: serviceType
        )
        
        mockScanner.simulateServiceFound(service)
    }
    
    return ExampleViewModelInjectionView(
        scanner: mockScanner,
        publishManager: MockBonjourPublishManager()
    )
}

// MARK: - Interactive Preview

/// This preview demonstrates how to create an interactive preview
/// where you can test different scenarios
#Preview("Interactive States") {
    InteractivePreviewContainer()
}

struct InteractivePreviewContainer: View {
    @State private var isScanning = false
    @State private var hasServices = false
    
    var body: some View {
        VStack {
            // Controls
            VStack(spacing: 16) {
                Toggle("Is Scanning", isOn: $isScanning)
                Toggle("Has Services", isOn: $hasServices)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Divider()
            
            // Preview content
            let dependencies = createDependencies()
            ExampleViewModelInjectionView()
                .environment(\.dependencies, dependencies)
        }
        .padding()
    }
    
    @MainActor private func createDependencies() -> DependencyContainer {
        let mockScanner = MockBonjourServiceScanner()
        mockScanner.isProcessing = isScanning
        
        let mockPublishManager = MockBonjourPublishManager()
        
        if hasServices {
            // Add sample services
            Task {
                let serviceType = BonjourServiceType(
                    name: "Sample",
                    type: "sample",
                    transportLayer: .tcp,
                    detail: "Sample service"
                )
                let service = BonjourService(
                    service: NetService(domain: "", type: serviceType.fullType, name: "Device", port: 8080),
                    serviceType: serviceType
                )
                try? await mockPublishManager.publish(service: service)
            }
        }
        
        return DependencyContainer(
            bonjourServiceScanner: mockScanner,
            bonjourPublishManager: mockPublishManager
        )
    }
}

// MARK: - Real BonjourScanForServicesView Preview Example

#Preview("Bonjour Scan View - Empty") {
    NavigationStack {
        BonjourScanForServicesView(
            scanner: MockBonjourServiceScanner()
        )
    }
}

#Preview("Bonjour Scan View - Scanning") {
    let mockScanner = MockBonjourServiceScanner()
    mockScanner.isProcessing = true
    
    return NavigationStack {
        BonjourScanForServicesView(scanner: mockScanner)
    }
}

#Preview("Bonjour Scan View - With Services") {
    let mockScanner = MockBonjourServiceScanner()
    
    // Simulate some discovered services
    Task {
        let serviceTypes = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web Server"),
            BonjourServiceType(name: "SSH", type: "ssh", transportLayer: .tcp, detail: "SSH Server"),
            BonjourServiceType(name: "AFP", type: "afpovertcp", transportLayer: .tcp, detail: "Apple File Server")
        ]
        
        for (index, serviceType) in serviceTypes.enumerated() {
            let service = BonjourService(
                service: NetService(
                    domain: "local.",
                    type: serviceType.fullType,
                    name: "Device \(index + 1)",
                    port: Int32(8080 + index)
                ),
                serviceType: serviceType
            )
            mockScanner.simulateServiceFound(service)
        }
    }
    
    return NavigationStack {
        BonjourScanForServicesView(scanner: mockScanner)
    }
}
