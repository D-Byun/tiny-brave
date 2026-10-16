import SwiftUI
import XCTest
@testable import TinyBrave

final class CategoryColorTests: XCTestCase {
    func testEveryCategoryHasItsOwnColorInEveryTheme() {
        for theme in AppTheme.allCases {
            let colors = BraveCategory.allCases.map { $0.color(in: theme.palette) }
            XCTAssertEqual(Set(colors).count, BraveCategory.allCases.count, "\(theme.title) reuses a category color")
        }
    }

    func testLightThemesUseTheMockColors() {
        let palette = AppTheme.sunny.palette
        XCTAssertEqual(BraveCategory.connect.color(in: palette), Color(hex: 0xBCE3E9))
        XCTAssertEqual(BraveCategory.speak.color(in: palette), Color(hex: 0xF1A7AA))
        XCTAssertEqual(BraveCategory.try.color(in: palette), Color(hex: 0xAFD5A2))
        XCTAssertEqual(BraveCategory.reset.color(in: palette), Color(hex: 0xC9B9E7))
    }

    func testDarkThemeUsesDeeperShades() {
        XCTAssertNotEqual(BraveCategory.connect.color(in: AppTheme.dark.palette), BraveCategory.connect.color(in: AppTheme.sunny.palette))
    }
}
