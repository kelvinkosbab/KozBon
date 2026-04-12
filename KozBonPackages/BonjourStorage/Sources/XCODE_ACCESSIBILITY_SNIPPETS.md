# Xcode Snippets for Accessibility

This document provides Xcode code snippets to help implement accessibility features quickly and correctly.

## How to Add These Snippets to Xcode

1. Copy the code block
2. In Xcode, go to Editor > Create Code Snippet (or drag selected code to the snippet library)
3. Set the completion shortcut as indicated
4. Set the platform to "iOS" or "All"
5. Set the language to "Swift"

## Snippets

### 1. Accessible View Template
**Shortcut:** `a11y-view`

```swift
import SwiftUI

/// <#View Description#>
///
/// Accessibility features:
/// - VoiceOver labels for all interactive elements
/// - Dynamic Type support with scaled metrics
/// - Custom accessibility actions for quick access
/// - Reduce Motion support
public struct <#ViewName#>: View {
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var spacing: CGFloat = 10
    
    public var body: some View {
        <#View Content#>
            .accessibilityIdentifier("<#identifier#>")
    }
}
```

### 2. Accessible List Row
**Shortcut:** `a11y-row`

```swift
<#RowContent#>
    .accessibilityLabel("<#combined label#>")
    .accessibilityHint("<#action hint#>")
    .accessibilityIdentifier("<#row_identifier#>")
    .accessibilityActions {
        Button("<#Action 1#>") {
            <#action1#>
        }
        Button("<#Action 2#>") {
            <#action2#>
        }
    }
```

### 3. Accessible Form Section
**Shortcut:** `a11y-section`

```swift
Section {
    <#TextField or other input#>
        .accessibilityLabel("<#field label#>")
        .accessibilityHint("<#field hint#>")
} header: {
    Text(<#header text#>)
        .accessibilityAddTraits(.isHeader)
} footer: {
    if let error = <#errorVar#> {
        Text(verbatim: error)
            .foregroundStyle(.red)
            .accessibilityLabel("Error: \(error)")
    }
}
```

### 4. Accessible TextField
**Shortcut:** `a11y-textfield`

```swift
TextField("<#placeholder#>", text: $<#binding#>)
    .accessibilityLabel("<#label#>")
    .accessibilityHint("<#hint#>")
    .accessibilityValue(<#binding#>.isEmpty ? "Empty" : <#binding#>)
```

### 5. Accessible Button
**Shortcut:** `a11y-button`

```swift
Button(role: <#.none or .destructive or .cancel#>) {
    <#action#>
} label: {
    Label("<#text#>", systemImage: "<#icon#>")
}
.disabled(<#condition#>)
.accessibilityHint(<#condition#> ? "" : "<#why disabled#>")
.accessibilityIdentifier("<#button_id#>")
```

### 6. Scaled Metric Properties
**Shortcut:** `a11y-metrics`

```swift
@ScaledMetric private var spacing: CGFloat = <#value#>
@ScaledMetric private var iconSize: CGFloat = <#value#>
```

### 7. Accessible HStack/VStack with Combined Label
**Shortcut:** `a11y-stack`

```swift
<#H or V#>Stack(spacing: <#spacing#>) {
    <#content#>
}
.accessibilityElement(children: .combine)
.accessibilityLabel("<#combined label#>")
.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

### 8. Accessible Image
**Shortcut:** `a11y-image`

```swift
Image(systemName: "<#icon#>")
    .font(.system(size: <#scaledSize#>))
    <#.accessibilityHidden(true) for decorative or .accessibilityLabel("description") for informative#>
```

### 9. Accessible Custom Actions
**Shortcut:** `a11y-actions`

```swift
.accessibilityActions {
    Button("<#Action 1#>") {
        <#action1#>
    }
    Button("<#Action 2#>") {
        <#action2#>
    }
    Button("<#Destructive Action#>", role: .destructive) {
        <#destructive action#>
    }
}
```

### 10. Accessible Swipe Actions
**Shortcut:** `a11y-swipe`

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        <#delete action#>
    } label: {
        Label("<#Delete#>", systemImage: "trash")
    }
    .accessibilityLabel("<#Delete item.name#>")
    .accessibilityHint("Double tap to delete")
}
```

### 11. Accessible Loading State
**Shortcut:** `a11y-loading`

```swift
if <#isLoading#> {
    HStack(spacing: 8) {
        ProgressView()
        Text("<#Loading message#>")
            .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("<#Loading message#>")
}
```

### 12. Accessible Error State
**Shortcut:** `a11y-error`

```swift
if let error = <#errorVar#> {
    Text(error)
        .foregroundStyle(.red)
        .accessibilityLabel("Error: \(error)")
}
```

### 13. Reduce Motion Animation
**Shortcut:** `a11y-animation`

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

withAnimation(reduceMotion ? nil : .default) {
    <#state change#>
}
```

### 14. Accessible Navigation Sheet
**Shortcut:** `a11y-sheet`

```swift
NavigationStack {
    <#content#>
        .navigationTitle("<#title#>")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    <#dismiss#>
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
                .accessibilityIdentifier("cancel_button")
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    <#confirm action#>
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .disabled(<#!isValid#>)
                .accessibilityHint(<#isValid#> ? "" : "<#why disabled#>")
                .accessibilityIdentifier("done_button")
            }
        }
}
.accessibilityIdentifier("<#sheet_id#>")
```

### 15. Accessible Context Menu
**Shortcut:** `a11y-context`

```swift
.accessibilityHint("Long press for options")
.accessibilityActions {
    Button("<#Action 1#>") { <#action1#> }
    Button("<#Action 2#>") { <#action2#> }
}
.contextMenu {
    Button {
        <#action1#>
    } label: {
        Label("<#Action 1#>", systemImage: "<#icon#>")
    }
    
    Button {
        <#action2#>
    } label: {
        Label("<#Action 2#>", systemImage: "<#icon#>")
    }
}
```

### 16. Accessible Color Usage
**Shortcut:** `a11y-color`

```swift
HStack {
    Image(systemName: "<#status icon#>")
        .foregroundStyle(<#color#>)
    Text("<#status text#>")
        .foregroundStyle(.primary)
}
// ✅ Good: Uses both icon and text, not color alone
```

### 17. Dynamic Type Size Limit
**Shortcut:** `a11y-limit`

```swift
.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
// or for more accessibility
.dynamicTypeSize(...DynamicTypeSize.accessibility1)
// or for headers
.dynamicTypeSize(...DynamicTypeSize.accessibility3)
```

### 18. Complete Accessible Custom View Template
**Shortcut:** `a11y-custom-view`

```swift
import SwiftUI

/// <#View Description#>
///
/// This view provides full accessibility support:
/// - Dynamic Type with scaled metrics
/// - VoiceOver labels and hints
/// - Custom accessibility actions
/// - Reduce Motion support
public struct <#ViewName#>: View {
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var spacing: CGFloat = 10
    @ScaledMetric private var iconSize: CGFloat = 20
    
    let <#properties#>
    
    public init(<#parameters#>) {
        self.<#properties#> = <#parameters#>
    }
    
    public var body: some View {
        <#H or V#>Stack(spacing: spacing) {
            Image(systemName: "<#icon#>")
                .font(.system(size: iconSize))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("<#title#>")
                    .font(.headline)
                Text("<#detail#>")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("<#combined label#>")
        .accessibilityHint("<#hint#>")
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

#Preview {
    <#ViewName#>(<#preview parameters#>)
}
```

## Quick Test Snippet

### 19. VoiceOver Test Function
**Shortcut:** `a11y-test`

```swift
#if DEBUG
private func testAccessibility() {
    // Enable VoiceOver: Cmd + F5 in Simulator
    // Or: Settings > Accessibility > VoiceOver on device
    
    // Test checklist:
    // ✓ Navigate through entire view with VoiceOver
    // ✓ Verify all interactive elements are accessible
    // ✓ Check custom actions appear in rotor
    // ✓ Verify section headers appear in headings rotor
    // ✓ Test at maximum text size (Settings > Display & Text Size)
    // ✓ Enable Reduce Motion and verify animations
}
#endif
```

## Build Phase Script for Accessibility Validation

Add this to your Build Phases to warn about missing accessibility:

```bash
#!/bin/bash

# Find Swift files with interactive elements but missing accessibility
echo "Checking for accessibility issues..."

# Check for buttons without identifiers
grep -r "Button\s*{" . --include="*.swift" | while read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    if ! grep -q "accessibilityIdentifier" "$file"; then
        echo "warning: $file may have buttons without accessibility identifiers"
    fi
done

# Check for List without identifiers  
grep -r "^[[:space:]]*List\s*{" . --include="*.swift" | while read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    if ! grep -q "accessibilityIdentifier" "$file"; then
        echo "warning: $file may have Lists without accessibility identifiers"
    fi
done

echo "Accessibility check complete"
```

## Unit Test Template for Accessibility

### 20. Accessibility UI Test Template
**Shortcut:** `a11y-uitest`

```swift
import XCTest

final class <#ViewName#>AccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testVoiceOverLabels() {
        // Navigate to view
        <#navigation steps#>
        
        // Verify accessibility identifiers exist
        let mainView = app.otherElements["<#view_identifier#>"]
        XCTAssertTrue(mainView.exists, "Main view should be accessible")
        
        // Verify button labels
        let saveButton = app.buttons["save_button"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        XCTAssertEqual(saveButton.label, "Save", "Save button should have correct label")
        
        // Verify interactive elements
        let textField = app.textFields["<#field_identifier#>"]
        XCTAssertTrue(textField.exists, "Text field should be accessible")
    }
    
    func testAccessibilityActions() {
        <#navigation steps#>
        
        let row = app.otherElements["<#row_identifier#>"]
        XCTAssertTrue(row.exists)
        
        // Verify custom actions exist
        // Note: Testing custom actions requires enabling VoiceOver in test
    }
    
    func testDynamicType() {
        // Set large text size
        app.launchArguments.append("-UIPreferredContentSizeCategoryName")
        app.launchArguments.append("UICTContentSizeCategoryAccessibilityXL")
        app.launch()
        
        <#navigation steps#>
        
        // Verify layout doesn't break
        let mainView = app.otherElements["<#view_identifier#>"]
        XCTAssertTrue(mainView.exists, "View should render with large text")
    }
}
```

---

## Integration with Xcode

### Keyboard Shortcuts to Remember

- **Cmd + F5**: Toggle VoiceOver in Simulator
- **Debug > Accessibility Inspector**: Open accessibility inspector
- **Product > Analyze**: Run static analysis (including accessibility)
- **Editor > Create Code Snippet**: Save selected code as snippet

### Xcode Build Settings

Add these to catch accessibility issues:

```
// In Build Settings
SWIFT_TREAT_WARNINGS_AS_ERRORS = YES (for CI builds)
RUN_CLANG_STATIC_ANALYZER = YES
CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES
```

---

*Xcode Integration Version: 1.0*  
*Created: April 12, 2026*
