//
//  AmbientMeshWaveTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import Foundation
@testable import BonjourUI

@Suite("AmbientMeshWave · mesh geometry")
struct AmbientMeshWaveTests {

    /// A 4×4 mesh needs exactly sixteen control points; `MeshGradient`
    /// traps at runtime on a count mismatch.
    @Test("Produces exactly sixteen points for the 4x4 mesh")
    func producesSixteenPoints() {
        #expect(AmbientMeshWave.points(at: 0).count == 16)
        #expect(AmbientMeshWave.points(at: 1_234.5).count == 16)
    }

    /// Drifting corners would pull the mesh away from the frame edge
    /// and expose the clear background through the gap.
    @Test("Pins all four corners at every point in time", arguments: [0.0, 3.7, 91.2, 1_000_000.0])
    func pinsCorners(_ time: TimeInterval) {
        let points = AmbientMeshWave.points(at: time)

        #expect(points[0] == SIMD2<Float>(0, 0))
        #expect(points[3] == SIMD2<Float>(1, 0))
        #expect(points[12] == SIMD2<Float>(0, 1))
        #expect(points[15] == SIMD2<Float>(1, 1))
    }

    /// Edge points may slide along their edge but never inward — an
    /// edge point that left its edge would open the same gap a
    /// drifting corner does.
    @Test("Keeps edge points on their edge", arguments: [0.0, 5.2, 88.9, 500_000.0])
    func pinsEdges(_ time: TimeInterval) {
        let points = AmbientMeshWave.points(at: time)

        // Top and bottom rows hold y; left and right columns hold x.
        #expect(points[1].y == 0 && points[2].y == 0)
        #expect(points[13].y == 1 && points[14].y == 1)
        #expect(points[4].x == 0 && points[8].x == 0)
        #expect(points[7].x == 1 && points[11].x == 1)
    }

    /// Every interior point must stay inside the unit square, or the
    /// mesh folds over itself and renders as a visible crease.
    @Test("Keeps every point within the unit square")
    func staysInUnitSquare() {
        for step in 0..<2_000 {
            let time = Double(step) * 0.37
            for point in AmbientMeshWave.points(at: time) {
                #expect(point.x >= 0 && point.x <= 1)
                #expect(point.y >= 0 && point.y <= 1)
            }
        }
    }

    /// The whole reason for the amplitude budget: two control points
    /// that cross render as a visible crease, so interior points must
    /// stay ordered within their row and column.
    @Test("Never lets control points cross")
    func neverCrosses() {
        for step in 0..<2_000 {
            let points = AmbientMeshWave.points(at: Double(step) * 0.37)

            for row in 0..<4 {
                for column in 0..<3 {
                    let leading = points[row * 4 + column]
                    let trailing = points[row * 4 + column + 1]
                    #expect(leading.x < trailing.x)
                }
            }

            for column in 0..<4 {
                for row in 0..<3 {
                    let upper = points[row * 4 + column]
                    let lower = points[(row + 1) * 4 + column]
                    #expect(upper.y < lower.y)
                }
            }
        }
    }

    /// The paused rendering pins time to zero, so that frame has to be
    /// a stable, well-formed mesh rather than a special case.
    @Test("Is deterministic for a given time")
    func isDeterministic() {
        #expect(AmbientMeshWave.points(at: 42.0) == AmbientMeshWave.points(at: 42.0))
    }

    /// Guards the drift itself — if the sine terms were dropped the
    /// suite above would still pass on a completely static mesh.
    @Test("Moves interior points as time advances")
    func driftsOverTime() {
        let start = AmbientMeshWave.points(at: 0)
        let later = AmbientMeshWave.points(at: 12.0)

        #expect(start != later)
        // Index 5 is an interior point, which moves on both axes.
        #expect(start[5] != later[5])
    }

    /// The colour count has to match the point count or `MeshGradient`
    /// traps the same way a short point array does.
    @Test("Produces one alpha per control point")
    func producesOneAlphaPerPoint() {
        #expect(AmbientMeshWave.alphas(at: 0).count == 16)
        #expect(AmbientMeshWave.alphas(at: 77.3).count == 16)
    }

    /// An alpha outside 0...1 is silently clamped, which would flatten
    /// the crest at whichever end it overshot.
    @Test("Keeps every alpha within a usable range")
    func alphasStayInRange() {
        for step in 0..<2_000 {
            for alpha in AmbientMeshWave.alphas(at: Double(step) * 0.37) {
                #expect(alpha > 0 && alpha < 1)
            }
        }
    }

    /// Alpha travelling across the grid is what actually reads as
    /// flow — the geometry alone is too subtle to notice, so a static
    /// palette would leave the wash looking frozen.
    @Test("Travels the brightness crest as time advances")
    func crestTravels() {
        let start = AmbientMeshWave.alphas(at: 0)
        let later = AmbientMeshWave.alphas(at: 1.5)

        #expect(start != later)
        #expect(start == AmbientMeshWave.alphas(at: 0))
    }

    /// A crest only reads as a band if neighbouring cells differ. A
    /// uniform grid would pulse the whole sheet instead.
    @Test("Varies alpha across the grid at a fixed time")
    func crestVariesAcrossGrid() throws {
        let alphas = AmbientMeshWave.alphas(at: 4.0)
        let highest = try #require(alphas.max())
        let lowest = try #require(alphas.min())

        #expect(highest - lowest > 0.2)
    }

    /// Two tabs on screen at once (split view on iPad / macOS) would
    /// otherwise render the same frame of the same wave.
    @Test("Offsets each palette's wave")
    func palettePhasesDiffer() {
        let offsets = [
            AmbientMeshPalette.discover,
            .library,
            .preferences,
            .chat
        ].map(\.phaseOffset)

        #expect(Set(offsets).count == offsets.count)
    }

    /// A palette phase has to actually reach the wave, or the tabs
    /// stay in lockstep no matter what the offsets say.
    @Test("Applies the palette phase to points and alphas")
    func phaseReachesTheWave() {
        let unshifted = AmbientMeshWave.points(at: 3.0)
        let shifted = AmbientMeshWave.points(at: 3.0, phase: 1.7)

        #expect(unshifted != shifted)
        #expect(AmbientMeshWave.alphas(at: 3.0) != AmbientMeshWave.alphas(at: 3.0, phase: 1.7))
    }

    /// The layout indexes a three-colour array, so an out-of-range
    /// entry is a crash and a missing accent is a palette that
    /// silently loses one of its hues.
    @Test("Lays out sixteen cells over exactly three accents")
    func accentLayoutCoversThreeAccents() {
        let layout = AmbientMeshPalette.accentLayout

        #expect(layout.count == 16)
        #expect(Set(layout) == [0, 1, 2])
    }
}

// MARK: - AmbientMeshIntensityTests

@Suite("AmbientMeshIntensity")
struct AmbientMeshIntensityTests {

    /// The placeholder column has to read as the *secondary* half of
    /// a wide window — same water, clearly lighter.
    @Test("Subdued is lighter than standard, and neither is invisible")
    func subduedIsLighter() {
        #expect(AmbientMeshIntensity.standard.opacityScale == 1.0)
        #expect(AmbientMeshIntensity.subdued.opacityScale < AmbientMeshIntensity.standard.opacityScale)
        #expect(AmbientMeshIntensity.subdued.opacityScale > 0)
    }
}
