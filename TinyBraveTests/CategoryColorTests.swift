import SwiftUI
import XCTest
@testable import TinyBrave

final class CategoryColorTests: XCTestCase {
    func testEveryCategoryHasItsOwnColor() {
        let colors = BraveCategory.allCases.map(\.color)
        XCTAssertEqual(Set(colors).count, BraveCategory.allCases.count)
    }

    func testCategoriesUseTheMockColors() {
        XCTAssertEqual(BraveCategory.connect.color, Color(hex: 0xBCE3E9))
        XCTAssertEqual(BraveCategory.speak.color, Color(hex: 0xF1A7AA))
        XCTAssertEqual(BraveCategory.try.color, Color(hex: 0xAFD5A2))
        XCTAssertEqual(BraveCategory.reset.color, Color(hex: 0xC9B9E7))
    }
}
