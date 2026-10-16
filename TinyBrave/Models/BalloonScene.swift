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
}
