//
//  LocalizedStringResource+Views.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - LocalizedStringResource convenience for SwiftUI views
//
// Reserved for any future SwiftUI overloads the project needs
// for `LocalizedStringResource`. As of the Xcode 27 / iOS 26
// SDK, Apple ships native overloads for `Label.init(_:systemImage:)`,
// `Button.init(_:action:)`, `Button.init(_:role:action:)`,
// `accessibilityLabel(_:)`, `accessibilityHint(_:)`, and
// `accessibilityValue(_:)` accepting `LocalizedStringResource`
// directly — and those overloads back-deploy through the SDK
// to the project's iOS 18.6 / macOS 15.6 / visionOS 26.0
// deployment targets. So `Label(Strings.Foo.bar, systemImage: …)`,
// `Button(Strings.Foo.bar) { … }`, and the accessibility modifiers
// all work out of the box without our extensions.
//
// Adding our own overloads here previously created
// "ambiguous use" errors at call sites because both Apple's
// and ours matched a `LocalizedStringResource` argument with
// equal specificity. Keep this file empty as documentation,
// and add an overload here only if a future version of the
// SDK regresses the native one.
