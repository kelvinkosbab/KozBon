//
//  AmbientMeshBackgroundTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import Foundation
@testable import BonjourUI

@Suite("AmbientMeshBackground · mesh geometry")
struct AmbientMeshBackgroundTests {

    /// A 3×3 mesh needs exactly nine control points; `MeshGradient`
    /// traps at runtime on a count mismatch.
    @Test("Produces exactly nine points for the 3x3 mesh")
    func producesNinePoints() {
        #expect(AmbientMeshBackground.points(at: 0).count == 9)
        #expect(AmbientMeshBackground.points(at: 1_234.5).count == 9)
    }

    /// Drifting corners would pull the mesh away from the frame edge
    /// and expose the clear background through the gap.
    @Test("Pins all four corners at every point in time", arguments: [0.0, 3.7, 91.2, 1_000_000.0])
    func pinsCorners(_ time: TimeInterval) {
        let points = AmbientMeshBackground.points(at: time)

        #expect(points[0] == SIMD2<Float>(0, 0))
        #expect(points[2] == SIMD2<Float>(1, 0))
        #expect(points[6] == SIMD2<Float>(0, 1))
        #expect(points[8] == SIMD2<Float>(1, 1))
    }

    /// Every interior point must stay inside the unit square, or the
    /// mesh folds over itself and renders as a visible crease.
    @Test("Keeps every point within the unit square")
    func staysInUnitSquare() {
        for step in 0..<2_000 {
            let time = Double(step) * 0.37
            for point in AmbientMeshBackground.points(at: time) {
                #expect(point.x >= 0 && point.x <= 1)
                #expect(point.y >= 0 && point.y <= 1)
            }
        }
    }

    /// The paused rendering pins time to zero, so that frame has to be
    /// a stable, well-formed mesh rather than a special case.
    @Test("Is deterministic for a given time")
    func isDeterministic() {
        #expect(AmbientMeshBackground.points(at: 42.0) == AmbientMeshBackground.points(at: 42.0))
    }

    /// Guards the drift itself — if the sine terms were dropped the
    /// suite above would still pass on a completely static mesh.
    @Test("Moves interior points as time advances")
    func driftsOverTime() {
        let start = AmbientMeshBackground.points(at: 0)
        let later = AmbientMeshBackground.points(at: 12.0)

        #expect(start != later)
        // Index 4 is the centre point, which drifts on both axes.
        #expect(start[4] != later[4])
    }
}
