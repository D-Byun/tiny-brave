import Foundation

/// How the balloon sits in its sky scene at a given puff count: grounded at 0, then swaying,
/// lifting, dancing and zipping higher until it reaches the top at `BraveProgress.goal`.
enum BalloonScene: String, Equatable {
    case grounded, sway, lift, dance, zip, final

    static func stage(puffs: Int) -> BalloonScene {
        switch BraveProgress.done(puffs) {
        case 0: .grounded
        case 1...8: .sway
        case 9...18: .lift
        case 19...25: .dance
        case 26..<BraveProgress.goal: .zip
        default: .final
        }
    }

    struct Motion: Equatable {
        /// 0 sits on the ground, 1 is as high as the scene allows. Eased so early puffs lift the most.
        let lift: Double
        /// Horizontal drift in points; it widens as the balloon gets braver.
        let drift: Double
    }

    static func motion(puffs: Int) -> Motion {
        let total = BraveProgress.done(puffs)
        let progress = Double(total) / Double(BraveProgress.goal)
        let eased = 1 - pow(1 - progress, 3)
        let amplitude = 4 + 22 * pow(progress, 1.25)
        let drift = total == BraveProgress.goal ? 0 : sin(Double(total) * .pi / 15) * amplitude
        return Motion(lift: eased, drift: drift)
    }

    /// How far the idle glide reaches: left and right drift, the lift at the two ends and at the middle, and the tilt, all in points and degrees.
    struct Glide: Equatable {
        let left: Double, right: Double, up: Double, mid: Double, tilt: Double
    }

    var glide: Glide {
        switch self {
        case .grounded: Glide(left: -3, right: 4, up: -3, mid: -5, tilt: 1)
        case .sway: Glide(left: -6, right: 7, up: -6, mid: -10, tilt: 2)
        case .lift: Glide(left: -10, right: 11, up: -10, mid: -16, tilt: 2.5)
        case .dance: Glide(left: -16, right: 17, up: -14, mid: -21, tilt: 4)
        case .zip: Glide(left: -22, right: 23, up: -17, mid: -25, tilt: 4.5)
        case .final: Glide(left: -26, right: 27, up: -19, mid: -29, tilt: 5)
        }
    }

    struct Offset: Equatable {
        let x: Double, y: Double, tilt: Double
    }

    /// Where the idle glide has the balloon at `phase` (0...1 around an 8.8 second loop).
    func glideOffset(phase: Double) -> Offset {
        let g = glide
        let keys: [(t: Double, o: Offset)] = [
            (0, Offset(x: 0, y: 0, tilt: 0)),
            (0.24, Offset(x: g.right, y: g.up, tilt: g.tilt)),
            (0.51, Offset(x: 0, y: g.mid, tilt: 0)),
            (0.76, Offset(x: g.left, y: g.up, tilt: -g.tilt)),
            (1, Offset(x: 0, y: 0, tilt: 0)),
        ]
        let p = phase - floor(phase)
        guard let index = keys.indices.dropLast().last(where: { keys[$0].t <= p }) else { return keys[0].o }
        let a = keys[index], b = keys[index + 1]
        let raw = (p - a.t) / (b.t - a.t)
        let eased = raw * raw * (3 - 2 * raw)
        func mix(_ from: Double, _ to: Double) -> Double { from + (to - from) * eased }
        return Offset(x: mix(a.o.x, b.o.x), y: mix(a.o.y, b.o.y), tilt: mix(a.o.tilt, b.o.tilt))
    }

    /// Sky colors as RGB triples: the top and bottom of the gradient blend from pale to deep blue as the balloon climbs.
    static func sky(puffs: Int) -> (top: (Double, Double, Double), bottom: (Double, Double, Double)) {
        let p = Double(BraveProgress.done(puffs)) / Double(BraveProgress.goal)
        func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> (Double, Double, Double) {
            (a.0 + (b.0 - a.0) * p, a.1 + (b.1 - a.1) * p, a.2 + (b.2 - a.2) * p)
        }
        return (mix((184, 225, 242), (57, 155, 210)), mix((226, 241, 248), (143, 213, 238)))
    }
}
