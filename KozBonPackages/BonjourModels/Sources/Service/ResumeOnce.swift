//
//  ResumeOnce.swift
//  BonjourModels
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

// MARK: - ResumeOnce

/// Resumes a continuation the first time it's asked to, so a callback
/// and a timeout can race without a double resume.
@MainActor
final class ResumeOnce {

    private var continuation: CheckedContinuation<Void, Never>?

    init(_ continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}
