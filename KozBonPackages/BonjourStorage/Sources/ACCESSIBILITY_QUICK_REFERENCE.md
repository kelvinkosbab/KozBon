# Accessibility Quick Reference Guide

A quick reference for maintaining and extending accessibility features in the KozBon app.

## 🎯 Quick Checklist for New Views

When creating a new view, ensure:

- [ ] Add `@ScaledMetric` for custom spacing and icon sizes
- [ ] Set `.dynamicTypeSize()` limits for critical UI elements
- [ ] Add `.accessibilityLabel()` to combine multi-element information
- [ ] Add `.accessibilityHint()` to explain actions
- [ ] Add `.accessibilityIdentifier()` for UI testing
- [ ] Add `.accessibilityAddTraits(.isHeader)` to section headers
- [ ] Add `.accessibilityActions {}` for complex interactions
- [ ] Test with VoiceOver enabled
- [ ] Test with maximum text size

## 📋 Common Patterns

### Dynamic Type Support

```swift
// In your view
@ScaledMetric private var spacing: CGFloat = 10
@ScaledMetric private var iconSize: CGFloat = 20

// Use in layout
VStack(spacing: spacing) {
    Image(systemName: "icon")
        .font(.system(size: iconSize))
}
.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

### Combined Accessibility Labels

```swift
// For title-detail rows
TitleDetailStackView(title: "Hostname", detail: "example.local")
    .accessibilityLabel("Hostname, example.local")

// For multi-element headers
HStack {
    Image(systemName: "icon")
    Text("Title")
    Text("Detail")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Title, Detail")
```

### Section Headers

```swift
Section {
    // content
} header: {
    Text(Strings.Sections.sectionName)
        .accessibilityAddTraits(.isHeader)
}
```

### Custom Accessibility Actions

```swift
.accessibilityActions {
    Button("Copy value") {
        Clipboard.copy(value)
    }
    Button("Edit") {
        isEditing = true
    }
    Button("Delete", role: .destructive) {
        delete()
    }
}
```

### Accessibility Identifiers

```swift
Button("Save") { /* action */ }
    .accessibilityIdentifier("save_button")

List { /* content */ }
    .accessibilityIdentifier("main_list")

NavigationStack { /* content */ }
    .accessibilityIdentifier("settings_navigation")
```

### Disabled Button Hints

```swift
Button("Submit") { submit() }
    .disabled(!isFormValid)
    .accessibilityHint(isFormValid ? "" : "Complete all fields to enable")
```

### Form Fields

```swift
TextField("Port", value: $port, format: .number)
    .accessibilityLabel("Port number")
    .accessibilityHint("Enter a port between 1024 and 65535")
    .accessibilityValue(port.map { "\($0)" } ?? "")
    .keyboardType(.numberPad)
```

### Context Menu Items

```swift
.contextMenu {
    Button {
        Clipboard.copy(value)
    } label: {
        Label("Copy", systemImage: "doc.on.doc")
    }
}
.accessibilityHint("Long press to copy")
```

### Swipe Actions

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        delete(item)
    } label: {
        Label("Delete", systemImage: "trash")
    }
    .accessibilityLabel("Delete \(item.name)")
    .accessibilityHint("Double tap to delete")
}
```

### Loading States

```swift
if isLoading {
    HStack {
        ProgressView()
        Text("Loading...")
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Loading content")
}
```

### Error Messages

```swift
if let error = errorMessage {
    Text(error)
        .foregroundStyle(.red)
        .accessibilityLabel("Error: \(error)")
}
```

### Images

```swift
// Decorative images
Image(systemName: "icon")
    .accessibilityHidden(true)

// Informative images
Image(systemName: "icon")
    .accessibilityLabel("Service type indicator")
```

## 🔍 Testing Commands

### Simulator (macOS)

```bash
# Toggle VoiceOver
Cmd + F5

# Accessibility Inspector
Xcode > Debug > Accessibility Inspector
```

### Xcode Testing

```swift
import XCTest

func testAccessibility() {
    let app = XCUIApplication()
    app.launch()
    
    // Find by identifier
    let button = app.buttons["save_button"]
    XCTAssertTrue(button.exists)
    
    // Check label
    XCTAssertEqual(button.label, "Save")
    
    // Verify enabled state
    XCTAssertTrue(button.isEnabled)
}
```

## 🎨 Naming Conventions

### Accessibility Identifiers

Use snake_case with descriptive names:

- **Buttons:** `action_button` (e.g., `save_button`, `cancel_button`)
- **Lists:** `name_list` (e.g., `service_list`, `preferences_list`)
- **Views:** `view_name` (e.g., `detail_view`, `settings_view`)
- **Navigation:** `navigation_name` (e.g., `main_navigation`)
- **Sheets:** `sheet_name` (e.g., `edit_sheet`, `create_sheet`)

### Accessibility Labels

Use natural language:

- Combine related information: `"Hostname, example.local"`
- Be concise but descriptive: `"Delete service record"`
- Avoid redundancy: Don't repeat "button" or "label" (VoiceOver adds this)

### Accessibility Hints

Provide action guidance:

- Explain what will happen: `"Double tap to copy address"`
- Explain why disabled: `"Complete all fields to enable"`
- Keep it brief: One sentence maximum

## 🚫 Common Mistakes

### ❌ Don't Do This

```swift
// Redundant information
Button("Save") { }
    .accessibilityLabel("Save button")
    
// Missing combined label
HStack {
    Text("Name:")
    Text(name)
}
// VoiceOver reads: "Name, colon, John"

// Hard-coded spacing
VStack(spacing: 10) { }
// Doesn't scale with text size

// Missing identifier
Button("Submit") { }
// Can't be tested
```

### ✅ Do This Instead

```swift
// Semantic label
Button("Save") { }
    .accessibilityLabel("Save")
    
// Combined label
HStack {
    Text("Name:")
    Text(name)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Name, \(name)")

// Scaled spacing
@ScaledMetric private var spacing: CGFloat = 10
VStack(spacing: spacing) { }

// With identifier
Button("Submit") { }
    .accessibilityIdentifier("submit_button")
```

## 📱 Platform Considerations

### iOS/iPadOS

- Use `.navigationBarTitleDisplayMode(.inline)` for consistent VoiceOver
- Test in both portrait and landscape
- Test with different size classes

### macOS

- Test keyboard navigation (Tab, arrows)
- Verify menu items are accessible
- Test with full keyboard access enabled

### visionOS

- Consider depth and spatial positioning
- Test with hand gestures
- Verify glass effects don't obscure content

## 🔧 Debugging Tips

### VoiceOver Not Announcing Correctly

1. Check `.accessibilityLabel()` is set
2. Verify no conflicting `.accessibilityElement()` modifiers
3. Use Accessibility Inspector to see what VoiceOver reads

### Dynamic Type Not Scaling

1. Ensure using `@ScaledMetric` for custom values
2. Check `.dynamicTypeSize()` limits aren't too restrictive
3. Test with actual Dynamic Type settings, not just font sizes

### Custom Actions Not Appearing

1. Verify `.accessibilityActions {}` is applied to correct view
2. Check actions aren't hidden by other modifiers
3. Test on actual device (may not work in all simulator versions)

## 📚 Helpful Resources

- **HIG:** https://developer.apple.com/design/human-interface-guidelines/accessibility
- **SwiftUI Docs:** https://developer.apple.com/documentation/swiftui/view-accessibility
- **Testing Guide:** https://developer.apple.com/documentation/accessibility/testing-for-accessibility
- **WWDC Sessions:** Search "Accessibility" on developer.apple.com/videos

## 💡 Pro Tips

1. **Test Early:** Enable VoiceOver while developing, not just at the end
2. **Real Devices:** Always test on physical devices - simulators differ
3. **User Testing:** Get feedback from actual VoiceOver users if possible
4. **Incremental:** Add accessibility as you build, not as a separate task
5. **Consistency:** Use established patterns from this guide

---

*Quick Reference Version: 1.0*  
*Last Updated: April 12, 2026*
