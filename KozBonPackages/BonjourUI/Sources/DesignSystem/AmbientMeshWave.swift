//
//  AmbientMeshWave.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AmbientMeshWave

/// The wave model behind ``AmbientMeshBackground`` — mesh geometry
/// and per-cell alpha as pure functions of elapsed time.
///
/// Control points ride two travelling sine waves: a swell and a
/// faster cross-running ripple. Because each wave's phase depends on
/// the point's *position*, a crest holds its shape and moves across
/// the frame the way a swell moves across water, rather than the
/// whole sheet breathing in and out. The waves run at unrelated
/// speeds and in opposite directions, so the surface never returns to
/// a configuration a user can recognise as a loop.
///
/// Deliberately not a `View`: SwiftUI infers `@MainActor` for types
/// conforming to `View`, which would make this maths main-actor-bound
/// and unusable from a test process. Keeping it a plain struct also
/// means the whole model is testable without a rendering pass.
struct AmbientMeshWave {

    // MARK: - Tuning

    /// Mesh resolution. 4×4 buys twelve movable control points, which
    /// is the minimum that can hold a crest and a trough at the same
    /// time; a 3×3 mesh can only pulse.
    static let resolution = 4

    /// Amplitude of the primary swell, in unit-square coordinates.
    private static let swellAmplitude: Float = 0.09

    /// Amplitude of the cross-running ripple. Summed with the swell,
    /// the total stays under half the 1/3 grid spacing so no two
    /// control points can cross and crease the mesh.
    private static let rippleAmplitude: Float = 0.045

    /// Single knob for how fast the water moves. Scales every wave's
    /// angular frequency together, so raising it speeds the motion up
    /// without changing the shape of the surface. At `2.5` the four
    /// waves run at 4–7 second periods.
    private static let waveSpeed: Float = 2.5

    /// Mid-point of the per-cell alpha swing.
    /// ``AmbientMeshBackground`` then scales the whole thing by its
    /// own wash opacity.
    private static let baseAlpha: Double = 0.45

    /// How far alpha travels either side of ``baseAlpha``.
    private static let alphaSwing: Double = 0.30

    // MARK: - Geometry

    /// The sixteen control points of the 4×4 mesh at a given time.
    ///
    /// Edge points slide *along* their edge and the four corners are
    /// pinned outright. If either moved inward, the mesh would pull
    /// away from the frame and expose the background through the gap.
    ///
    /// - Parameters:
    ///   - time: Elapsed time in seconds. Any stable reference epoch
    ///     works; only differences matter.
    ///   - phase: Constant offset added to every wave, so two
    ///     palettes on screen at once aren't on the same frame.
    static func points(at time: TimeInterval, phase: Float = 0) -> [SIMD2<Float>] {
        let time = Float(time)
        let lastIndex = resolution - 1
        let spacing = Float(lastIndex)

        var points: [SIMD2<Float>] = []
        points.reserveCapacity(resolution * resolution)

        for row in 0..<resolution {
            for column in 0..<resolution {
                let restX = Float(column) / spacing
                let restY = Float(row) / spacing

                let onVerticalEdge = column == 0 || column == lastIndex
                let onHorizontalEdge = row == 0 || row == lastIndex

                points.append(
                    SIMD2(
                        onVerticalEdge
                            ? restX
                            : restX + lateralOffset(unitX: restX, unitY: restY, time: time, phase: phase),
                        onHorizontalEdge
                            ? restY
                            : restY + swellOffset(unitX: restX, unitY: restY, time: time, phase: phase)
                    )
                )
            }
        }

        return points
    }

    /// Vertical displacement — the rise and fall of the swell.
    ///
    /// The `-x` phase term is what makes it *travel*: a crest holds
    /// its shape and moves toward the trailing edge instead of the
    /// whole row rising together.
    private static func swellOffset(unitX: Float, unitY: Float, time: Float, phase: Float) -> Float {
        swellAmplitude * sin(waveSpeed * 0.42 * time - 3.1 * unitX + 0.9 * unitY + phase)
            + rippleAmplitude * sin(waveSpeed * 0.61 * time + 2.2 * unitX - 1.7 * unitY + 2.4 + phase)
    }

    /// Horizontal displacement — the lateral push that leans a crest
    /// as it passes. Without it the wave reads as a flag ripple
    /// rather than water.
    private static func lateralOffset(unitX: Float, unitY: Float, time: Float, phase: Float) -> Float {
        swellAmplitude * sin(waveSpeed * 0.37 * time - 2.6 * unitY + 1.6 + phase)
            + rippleAmplitude * sin(waveSpeed * 0.53 * time + 1.9 * unitX + 3.0 * unitY + 0.7 + phase)
    }

    // MARK: - Alpha

    /// Per-cell alpha at a given time.
    ///
    /// Alpha travels as a wave across the grid, in the same direction
    /// as the swell, so a crest arrives as a band of brightness. The
    /// geometry alone can't carry the motion: a fold-free mesh limits
    /// control points to about a tenth of the frame, which on its own
    /// reads as a barely-perceptible shift in tint rather than flow.
    ///
    /// - Parameters:
    ///   - time: Elapsed time in seconds.
    ///   - phase: The palette's wave offset, in radians.
    static func alphas(at time: TimeInterval, phase: Float = 0) -> [Double] {
        let time = Float(time)
        let spacing = Float(resolution - 1)

        return (0..<(resolution * resolution)).map { index in
            let row = Float(index / resolution) / spacing
            let column = Float(index % resolution) / spacing
            let crest = sin(waveSpeed * 0.45 * time - 2.4 * column + 1.1 * row + phase)

            return baseAlpha + alphaSwing * Double(crest)
        }
    }
}
