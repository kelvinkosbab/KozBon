//
//  Exports.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

// `BonjourAI` is now an umbrella module that wires the
// cloud-aware routing factories on top of the provider-specific
// implementations in `BonjourAIApple` and `BonjourAIAnthropic`.
// Consumers historically imported `BonjourAI` to reach the
// shared interfaces / value types that now live in
// `BonjourAICore`; re-export keeps that import surface working
// without forcing a sweeping refactor of every consumer.
@_exported import BonjourAICore
