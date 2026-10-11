//
//  AmbientMeshClockTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import Foundation
@testable import BonjourUI

@Suite("AmbientMeshClock · pause and resume")
struct AmbientMeshClockTests {

    @Test("Follows wall-clock time while running")
    func followsWallClock() {
        let clock = AmbientMeshClock()

        #expect(clock.time(at: 812_000_000) == 812_000_000)
    }

    /// The regression: a pause used to render time zero, a different
    /// frame from the one on screen.
    @Test("Holds the frame showing when paused")
    func holdsFrameWhenPaused() {
        var clock = AmbientMeshClock()
        clock.pause(at: 812_000_000)

        #expect(clock.time(at: 812_000_000) == 812_000_000)
        #expect(clock.time(at: 812_000_600) == 812_000_000)
    }

    @Test("Resumes from the held frame instead of jumping ahead")
    func resumesFromHeldFrame() {
        var clock = AmbientMeshClock()
        clock.pause(at: 1_000)
        clock.resume(at: 1_600)

        #expect(clock.time(at: 1_600) == 1_000)
        #expect(clock.time(at: 1_610) == 1_010)
    }

    @Test("Accumulates across several pauses")
    func accumulatesAcrossPauses() {
        var clock = AmbientMeshClock()
        clock.pause(at: 100)
        clock.resume(at: 160)
        clock.pause(at: 200)
        clock.resume(at: 300)

        #expect(clock.time(at: 300) == 140)
    }

    @Test("Keeps the first frame when paused twice")
    func ignoresRepeatedPause() {
        var clock = AmbientMeshClock()
        clock.pause(at: 100)
        clock.pause(at: 500)

        #expect(clock.time(at: 900) == 100)
    }

    @Test("Ignores a resume without a pause")
    func ignoresResumeWithoutPause() {
        var clock = AmbientMeshClock()
        clock.resume(at: 500)

        #expect(clock.time(at: 500) == 500)
    }
}
