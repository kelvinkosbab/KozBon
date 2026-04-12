# Accessibility System Architecture

## Document Flow

```
START: Need to create/modify UI
         |
         v
    Read .clinerules ────────────────┐
    (What MUST be done)              │
         |                           │
         v                           │
    Implement Feature                │
    Use QUICK_REFERENCE.md ──────────┤── During Development
    (How to do it)                   │
         |                           │
         v                           │
    Test with VoiceOver ─────────────┘
         |
         v
    Code Review Checklist
    (from .clinerules)
         |
         v
    Update IMPLEMENTATION_SUMMARY.md
    (if new patterns)
         |
         v
    DONE: Accessible Feature ✅
```

## Documentation Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    ACCESSIBILITY_README.md                   │
│                     (Central Hub & Index)                    │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        v                     v                     v
┌──────────────┐    ┌──────────────────┐    ┌──────────────┐
│ .clinerules  │    │ RECOMMENDATIONS  │    │ QUICK_REF    │
│              │    │                  │    │              │
│ THE LAW      │    │ THE WHY          │    │ THE HOW      │
│              │    │                  │    │              │
│ Mandatory    │    │ Comprehensive    │    │ Patterns &   │
│ Requirements │    │ Guide            │    │ Examples     │
└──────────────┘    └──────────────────┘    └──────────────┘
        │                     │                     │
        └─────────────────────┴─────────────────────┘
                              │
                              v
                    ┌──────────────────┐
                    │ IMPLEMENTATION   │
                    │ SUMMARY          │
                    │                  │
                    │ What's Done      │
                    └──────────────────┘
                              │
                              v
                    ┌──────────────────┐
                    │ XCODE_SNIPPETS   │
                    │                  │
                    │ Tools & Code     │
                    └──────────────────┘
```

## Developer Workflow

### New Developer Onboarding
```
Day 1: Read ACCESSIBILITY_README.md ───────► Understand the system
        │
        v
Day 1: Read .clinerules ───────────────────► Learn requirements
        │
        v
Day 2: Import XCODE_SNIPPETS.md snippets ──► Setup environment
        │
        v
Day 2-3: Enable VoiceOver, use app ────────► Experience it
        │
        v
Week 1: Implement first feature ───────────► Practice with QUICK_REF
        │
        v
Ongoing: Reference docs as needed ─────────► Build expertise
```

### Feature Development Workflow
```
┌──────────────────┐
│ Feature Request  │
└────────┬─────────┘
         │
         v
┌─────────────────────────────────────────┐
│ Plan: Review .clinerules requirements   │
└────────┬────────────────────────────────┘
         │
         v
┌─────────────────────────────────────────┐
│ Code: Use QUICK_REFERENCE.md patterns   │
└────────┬────────────────────────────────┘
         │
         v
┌─────────────────────────────────────────┐
│ Test: VoiceOver, Dynamic Type, Motion   │
└────────┬────────────────────────────────┘
         │
         v
┌─────────────────────────────────────────┐
│ Review: Code Review Checklist           │
└────────┬────────────────────────────────┘
         │
         v
┌─────────────────────────────────────────┐
│ Merge: Feature is accessible ✅         │
└─────────────────────────────────────────┘
```

## AI Assistant Integration

### How Claude Uses These Docs

```
User Request: "Create a settings view"
        │
        v
┌──────────────────────────────────────────┐
│ 1. Read .clinerules                      │
│    - Identify all requirements           │
│    - Plan accessibility features         │
└────────┬─────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────┐
│ 2. Reference QUICK_REFERENCE.md          │
│    - Copy patterns for forms             │
│    - Adapt to specific need              │
└────────┬─────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────┐
│ 3. Generate Code                         │
│    - Include @ScaledMetric               │
│    - Add accessibility labels            │
│    - Add identifiers                     │
│    - Add section header traits           │
└────────┬─────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────┐
│ 4. Verify Against .clinerules            │
│    - Check all requirements met          │
│    - Self-review using checklist         │
└────────┬─────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────┐
│ 5. Deliver Code                          │
│    - Include testing notes               │
│    - Highlight accessibility features    │
└──────────────────────────────────────────┘
```

## Testing Workflow

```
Feature Complete?
        │
        v
┌──────────────────────────────────────────┐
│ Local Testing                            │
│ - VoiceOver navigation                   │
│ - Maximum text size                      │
│ - Reduce Motion                          │
└────────┬─────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────┐
│ Xcode Accessibility Inspector            │
│ - Run audit                              │
│ - Check for warnings                     │
│ - Verify identifiers                     │
└────────┬─────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────┐
│ Code Review                              │
│ - Use checklist from .clinerules         │
│ - Verify patterns from QUICK_REF         │
└────────┬─────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────┐
│ Real Device Testing                      │
│ - Test on physical device                │
│ - Enable VoiceOver in Settings           │
│ - Complete user flows                    │
└────────┬─────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────┐
│ User Acceptance                          │
│ - Test with VoiceOver users if possible  │
│ - Gather feedback                        │
└────────┬─────────────────────────────────┘
         │
         v
Ready to Ship ✅
```

## Priority System

```
HIGH PRIORITY (Must Have)
├── Dynamic Type Support (@ScaledMetric)
├── VoiceOver Labels (all elements)
├── Accessibility Identifiers (all interactive)
├── Section Header Traits (.isHeader)
└── Form Field Labels & Hints

MEDIUM PRIORITY (Should Have)
├── Custom Accessibility Actions
├── Swipe Action Hints
├── Disabled Button Explanations
├── Loading State Announcements
└── Error State Labels

ADVANCED (Nice to Have)
├── Reduce Transparency Support
├── State Change Announcements
├── Haptic Feedback
├── Voice Control Optimization
└── Advanced Rotor Support
```

## Code Review Decision Tree

```
Is this a UI change?
        │
        ├─No───► Standard review process
        │
        └─Yes──► Continue
                 │
                 v
        Does it have @ScaledMetric?
                 │
                 ├─No───► ❌ REJECT
                 │
                 └─Yes──► Continue
                          │
                          v
        Accessibility identifiers present?
                          │
                          ├─No───► ❌ REJECT
                          │
                          └─Yes──► Continue
                                   │
                                   v
                Section headers have .isHeader?
                                   │
                                   ├─No───► ❌ REJECT
                                   │
                                   └─Yes──► Continue
                                            │
                                            v
                    VoiceOver tested?
                                            │
                                            ├─No───► ❌ REJECT
                                            │
                                            └─Yes──► Continue
                                                     │
                                                     v
                            Complex interactions have actions?
                                                     │
                                                     ├─No───► ❌ REJECT
                                                     │
                                                     └─Yes──► ✅ APPROVE
```

## Accessibility Feature Matrix

```
┌─────────────────┬──────────┬────────────┬──────────┬──────────┐
│ View Component  │ Dynamic  │ VoiceOver  │ Actions  │ Complete │
│                 │   Type   │  Labels    │          │          │
├─────────────────┼──────────┼────────────┼──────────┼──────────┤
│ TitleDetail     │    ✅    │     ✅     │    N/A   │    ✅    │
│ BlueSection     │    ✅    │     ✅     │    N/A   │    ✅    │
│ ServiceDetail   │    ✅    │     ✅     │    ✅    │    ✅    │
│ BroadcastView   │    ✅    │     ✅     │    ✅    │    ✅    │
│ CreateTxtRecord │    ⏭     │     ✅     │    N/A   │    ⏭     │
│ SupportedView   │    ⏭     │     ✅     │    ✅    │    ⏭     │
└─────────────────┴──────────┴────────────┴──────────┴──────────┘

Legend: ✅ Complete | ⏭ In Progress | ❌ Missing
```

## Documentation Maintenance

```
Code Change
     │
     v
Introduces new pattern?
     │
     ├─No───► No doc update needed
     │
     └─Yes──► Update docs
              │
              v
      Which document?
              │
              ├─ New requirement ────────► .clinerules
              │
              ├─ New pattern/example ────► QUICK_REFERENCE.md
              │
              ├─ Explanation of feature ─► RECOMMENDATIONS.md
              │
              ├─ Implementation details ─► IMPLEMENTATION_SUMMARY.md
              │
              └─ Xcode snippet ──────────► XCODE_SNIPPETS.md
```

## Learning Path Progression

```
Week 1
├── Read all documentation
├── Import Xcode snippets
├── Enable VoiceOver
└── Use app with VoiceOver

Week 2
├── Implement simple view
├── Practice VoiceOver testing
├── Use Accessibility Inspector
└── Review .clinerules daily

Week 3
├── Implement complex feature
├── Add custom actions
├── Test Dynamic Type
└── Review peer code

Month 2
├── Mentor new developers
├── Contribute patterns
├── Update documentation
└── User testing sessions

Expert Level
├── Accessibility champion
├── Documentation maintainer
├── Pattern creator
└── Reviewer for all UI
```

## Success Metrics

```
Sprint Metrics
│
├── Accessibility Coverage
│   ├── Views with identifiers: __%
│   ├── Views with Dynamic Type: __%
│   ├── Views with custom actions: __%
│   └── Section headers with .isHeader: __%
│
├── Testing Metrics
│   ├── VoiceOver test hours: __
│   ├── Bugs found: __
│   └── Bugs fixed: __
│
└── Quality Metrics
    ├── Code reviews passed first time: __%
    ├── User feedback score: __/10
    └── WCAG compliance: __%
```

---

*This architecture supports accessibility-first development through clear documentation, workflows, and enforcement.*
