import XCTest
@testable import RoktUXHelper

@available(iOS 15, *)
final class TestOfferModelAccessibilityComparison: XCTestCase {

    func test_imageAltDuplicatesTitleLikeCopy_plainTitle_matches() {
        let sut = OfferModel.mock(copy: ["title": "Acme Brand"])
        XCTAssertTrue(sut.imageAltDuplicatesTitleLikeCopy("Acme Brand"))
    }

    func test_imageAltDuplicatesTitleLikeCopy_htmlWrappedTitle_matchesPlainAlt() {
        let sut = OfferModel.mock(copy: ["title": "<h2>Acme Brand</h2>"])
        XCTAssertTrue(sut.imageAltDuplicatesTitleLikeCopy("Acme Brand"))
    }

    func test_imageAltDuplicatesTitleLikeCopy_htmlEntities_matchDecodedAlt() {
        let sut = OfferModel.mock(copy: ["title": "Tom &amp; Jerry"])
        XCTAssertTrue(sut.imageAltDuplicatesTitleLikeCopy("Tom & Jerry"))
    }

    func test_imageAltDuplicatesTitleLikeCopy_mismatch_returnsFalse() {
        let sut = OfferModel.mock(copy: ["title": "<h2>Acme</h2>"])
        XCTAssertFalse(sut.imageAltDuplicatesTitleLikeCopy("Other Co"))
    }

    func test_imageAltDuplicatesTitleLikeCopy_subtitleKey_isIgnored() {
        let sut = OfferModel.mock(copy: ["subtitle": "<b>Acme</b>"])
        XCTAssertFalse(sut.imageAltDuplicatesTitleLikeCopy("Acme"))
    }
}
