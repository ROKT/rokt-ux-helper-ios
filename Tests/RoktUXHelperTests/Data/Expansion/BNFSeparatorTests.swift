import XCTest
@testable import RoktUXHelper

final class BNFSeparatorTests: XCTestCase {
    func test_utf16Count_shouldReturnPerDelimiter() {
        XCTAssertEqual(BNFSeparator.startDelimiter.utf16Count, 2)
        XCTAssertEqual(BNFSeparator.endDelimiter.utf16Count, 2)
        XCTAssertEqual(BNFSeparator.namespace.utf16Count, 1)
        XCTAssertEqual(BNFSeparator.alternative.utf16Count, 1)
    }
}
