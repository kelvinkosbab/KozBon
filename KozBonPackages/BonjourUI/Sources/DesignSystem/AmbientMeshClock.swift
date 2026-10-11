//
//  AmbientMeshClock.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AmbientMeshClock

/// The time ``AmbientMeshBackground`` renders, which stops while the
/// wash is paused and picks up where it left off on resume.
///
/// Rendering wall-clock time would make a pause snap to some other
/// frame and a resume jump forward by however long the pause lasted.
/// Instead the clock records the frame it stopped on, and on resume
/// shifts by the paused duration so the wave carries on from that
/// frame.
struct AmbientMeshClock: Equatable {

    /// The rendered time the wash stopped on, or `nil` while it runs.
    private(set) var frozenTime: TimeInterval?

    /// Total time spent paused, subtracted from wall-clock time.
    private(set) var pausedDuration: TimeInterval = 0

    /// The time to render for a given wall-clock date.
    func time(at date: TimeInterval) -> TimeInterval {
        frozenTime ?? date - pausedDuration
    }

    /// Holds the frame showing at `date`. A second pause keeps the
    /// first frame.
    mutating func pause(at date: TimeInterval) {
        guard frozenTime == nil else { return }
        frozenTime = time(at: date)
    }

    /// Continues from the held frame.
    mutating func resume(at date: TimeInterval) {
        guard let frozenTime else { return }
        pausedDuration = date - frozenTime
        self.frozenTime = nil
    }
}
