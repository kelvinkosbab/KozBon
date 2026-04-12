# Accessibility Recommendations for KozBon

This document outlines accessibility improvements for your BonjourStorage application. Your app already has good accessibility practices, but there's room for enhancement.

## ✅ Current Strengths

1. **Good use of accessibility labels and hints** throughout the UI
2. **Proper use of `accessibilityReduceMotion`** environment value
3. **Semantic labels** using the `Label` view with system images
4. **Context menus** with proper actions
5. **Localized strings** with type-safe constants
6. **Error announcements** with accessibility labels

## 🎯 High Priority Improvements

### 1. Dynamic Type Support

**Issue**: Your app doesn't currently adapt to user-preferred text sizes.

**Impact**: Users with vision impairments who need larger text may struggle to read content.

**Solution**: 

```swift
// Add to views that need to adapt to Dynamic Type
@Environment(\.dynamicTypeSize) private var dynamicTypeSize

// For fixed-size elements that need to scale
@ScaledMetric private var iconSize: CGFloat = 20

// Use in your views
Image(systemName: "icon.name")
    .font(.system(size: iconSize))
```

**Additional recommendations**:
- Set a maximum accessibility size for critical UI elements using `.dynamicTypeSize(...maxAccessibility3)`
- Test your app with the largest text sizes in Settings > Accessibility > Display & Text Size
- Consider providing a ScrollView for sheets and forms when text is large

### 2. VoiceOver Navigation Improvements

**Issue**: List items could provide better combined accessibility labels.

**Impact**: VoiceOver users hear fragmented information.

**Current code example**:
```swift
TitleDetailStackView(
    title: address.ipPortString,
    detail: address.protocol.stringRepresentation
)
.accessibilityHint(String(localized: Strings.Accessibility.longPressCopyAddress))
```

**Improved version** (already applied):
```swift
TitleDetailStackView(
    title: address.ipPortString,
    detail: address.protocol.stringRepresentation
)
.accessibilityLabel("\(address.ipPortString), \(address.protocol.stringRepresentation)")
.accessibilityHint(String(localized: Strings.Accessibility.longPressCopyAddress))
```

### 3. Accessibility Identifiers for Testing

**Issue**: Missing accessibility identifiers make UI testing difficult.

**Impact**: Harder to write automated accessibility tests.

**Solution** (already applied to broadcast view):
```swift
Button { /* action */ } label: {
    Label(String(localized: Strings.Buttons.cancel), systemImage: Iconography.cancel)
}
.accessibilityIdentifier("broadcast_cancel_button")
```

**Recommended identifiers to add**:
- `"service_detail_list"`
- `"txt_record_add_button"`
- `"service_type_picker"`
- `"ai_explanation_sheet"`
- `"preferences_ai_toggle"`

### 4. Form Field Accessibility

**Issue**: Number input fields lack explicit value announcements.

**Solution** (already applied):
```swift
TextField(
    String(localized: Strings.Placeholders.servicePortNumber),
    value: $port,
    format: .number
)
.accessibilityLabel(String(localized: Strings.Accessibility.portNumber))
.accessibilityHint(Strings.Accessibility.portHint(min: Constants.Network.minimumPort, max: Constants.Network.maximumPort))
.accessibilityValue(port.map { "\($0)" } ?? "")
.keyboardType(.numberPad)
```

### 5. AI Content Accessibility

**Issue**: Markdown headers in AI explanations aren't marked as headers for VoiceOver rotor.

**Solution** (already applied):
```swift
if paragraph.hasPrefix("# ") {
    Text(paragraph.dropFirst(2))
        .font(.title2).bold()
        .accessibilityAddTraits(.isHeader)
}
```

This allows VoiceOver users to navigate headings using the rotor.

## 🔧 Medium Priority Improvements

### 6. Loading States

**Current**: Loading indicators may not clearly announce state changes.

**Recommendation**:
```swift
HStack(spacing: 8) {
    ProgressView()
        .accessibilityLabel(String(localized: Strings.AIInsights.generating))
    Text(Strings.AIInsights.generating)
        .foregroundStyle(.secondary)
}
.accessibilityElement(children: .combine)
```

### 7. Button States

**Issue**: Disabled buttons should explain why they're disabled.

**Recommendation**:
```swift
Button {
    doneButtonSelected()
} label: {
    Label(String(localized: Strings.Buttons.done), systemImage: Iconography.confirm)
}
.disabled(!isFormValid)
.accessibilityHint(isFormValid ? "" : "Complete all required fields to enable this button")
```

### 8. Swipe Actions

**Current**: Swipe actions have good labels.

**Enhancement**:
```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        viewModel.deleteTxtRecord(dataRecord)
    } label: {
        Label(String(localized: Strings.Buttons.remove), systemImage: Iconography.remove)
    }
    .accessibilityLabel(Strings.Accessibility.remove(dataRecord.key))
    .accessibilityHint("Double tap to delete this TXT record") // Add this
    .tint(.red)
}
```

### 9. Section Headers

**Recommendation**: Add accessibility traits to section headers for better navigation.

```swift
Section {
    // content
} header: {
    Text(Strings.Sections.txtRecords)
        .accessibilityAddTraits(.isHeader)
}
```

### 10. Image Decorations

**Issue**: Some images may be decorative and should be hidden from VoiceOver.

**Recommendation**:
```swift
Image(systemName: serviceType.imageSystemName)
    .font(.title2)
    .foregroundStyle(.secondary)
    .accessibilityHidden(true) // If the text already describes the service
```

## 🌟 Advanced Enhancements

### 11. Custom Accessibility Actions

**Use case**: Provide quick actions for VoiceOver users without needing context menus.

```swift
TitleDetailStackView(
    title: dataRecord.key,
    detail: dataRecord.value
)
.accessibilityLabel("\(dataRecord.key): \(dataRecord.value)")
.accessibilityActions {
    Button("Copy key and value") {
        Clipboard.copy("\(dataRecord.key)=\(dataRecord.value)")
    }
    Button("Copy value only") {
        Clipboard.copy(dataRecord.value)
    }
    if viewModel.isPublished {
        Button("Edit") {
            viewModel.txtRecordToEdit = dataRecord
            viewModel.isCreateTxtRecordPresented = true
        }
        Button("Delete", role: .destructive) {
            viewModel.deleteTxtRecord(dataRecord)
        }
    }
}
```

### 12. Grouping Related Content

**Use case**: Combine multiple elements for better VoiceOver flow.

```swift
VStack {
    Image(systemName: subject.serviceType.imageSystemName)
        .font(.title2)
    Text(verbatim: subject.displayName)
        .font(.headline)
    Text(verbatim: subject.serviceType.fullType)
        .font(.caption)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(subject.displayName), \(subject.serviceType.name), \(subject.serviceType.fullType)")
```

### 13. Announce State Changes

**Use case**: Notify users when data updates.

```swift
import Accessibility

@State private var announcementMessage = ""

// When services are discovered or updated
.onChange(of: viewModel.dataRecords) { oldValue, newValue {
    if newValue.count > oldValue.count {
        announcementMessage = "New service discovered"
    }
}
.accessibilityAnnouncement($announcementMessage)
```

### 14. Reduce Transparency Support

**Recommendation**: Test your app with Reduce Transparency enabled.

```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency

// Adjust backgrounds
.background(
    reduceTransparency 
        ? Color.systemBackground 
        : Color.systemBackground.opacity(0.95)
)
```

### 15. Voice Control Support

**Recommendation**: Ensure all interactive elements have visible labels or can be targeted.

```swift
Button {
    // action
} label: {
    Label("Add TXT Record", systemImage: Iconography.add)
}
// Good: Has visible text that Voice Control can use

Image(systemName: "plus")
    .onTapGesture { /* action */ }
    .accessibilityLabel("Add TXT Record")
// Better, but not ideal for Voice Control - use Button instead
```

## 📝 Testing Checklist

- [ ] Test with VoiceOver enabled (iOS: Settings > Accessibility > VoiceOver)
- [ ] Test with largest text size (Settings > Accessibility > Display & Text Size)
- [ ] Test with Reduce Motion enabled
- [ ] Test with Reduce Transparency enabled
- [ ] Test with Voice Control enabled
- [ ] Test with Switch Control (if applicable)
- [ ] Test all forms can be completed using only VoiceOver
- [ ] Test all context menus are accessible
- [ ] Test color contrast meets WCAG 2.1 AA standards (use Xcode's Accessibility Inspector)
- [ ] Test keyboard navigation on macOS
- [ ] Test with Assistive Touch on iOS

## 🛠 Tools

1. **Xcode Accessibility Inspector**: Debug > Accessibility Inspector
2. **Simulator Accessibility Shortcuts**: 
   - VoiceOver: Cmd + F5
   - Increase text size: Accessibility Inspector > Settings
3. **Real Device Testing**: Always test on actual devices with VoiceOver
4. **Accessibility Audit**: Product > Analyze > Accessibility

## 📚 Resources

- [Apple Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [WWDC Accessibility Sessions](https://developer.apple.com/videos/topics/accessibility)
- [SwiftUI Accessibility Documentation](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [Testing for Accessibility](https://developer.apple.com/documentation/accessibility/testing-for-accessibility)

## 🎯 Priority Implementation Order

1. ✅ Add accessibility identifiers (completed)
2. ✅ Improve VoiceOver labels for composite views (completed)
3. ✅ Add header traits to markdown content (completed)
4. ✅ Improve form field accessibility (completed)
5. ⏭ Add Dynamic Type support throughout the app
6. ⏭ Add custom accessibility actions for complex interactions
7. ⏭ Test with all accessibility features enabled
8. ⏭ Add reduce transparency support
9. ⏭ Implement accessibility announcements for state changes
10. ⏭ Add accessibility hints for disabled states

---

*Document created: April 12, 2026*  
*Last updated: April 12, 2026*
