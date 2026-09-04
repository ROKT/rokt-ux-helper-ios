import XCTest
@testable import RoktUXHelper

final class NumericPredicateTextExpansionTests: XCTestCase {
    func test_numericPredicatesConvertCatalogTextAfterExpansion() throws {
        assertNumeric("DATA.catalogItem.minItemCount:sliceText[Chars,1]|2", equals: 1, context: try makeContext())
    }

    func test_numericPredicatesConvertCreativeNumericTextAfterExpansion() throws {
        assertNumeric("DATA.creativeCopy.count:sliceText[Chars,1]|2", equals: 1, context: try makeContext())
    }

    func test_numericPredicatesConvertCreativeTextSlicesThatBecomeNumeric() throws {
        assertNumeric("DATA.creativeCopy.mixed:sliceText[Chars,1]|2", equals: 7, context: try makeContext())
    }

    func test_numericPredicatesConvertSupportedStateAfterTextExpansion() throws {
        let context = try makeContext()
        for (key, expected) in [("IndicatorPosition", 1), ("TotalOffers", 3)] {
            assertNumeric("STATE.\(key):sliceText[Chars,1]|2", equals: expected, context: context)
        }
    }

    func test_numericPredicatesKeepTheFirstExpandedAlternative() throws {
        let context = try makeContext()
        let cases = [
            ("DATA.catalogItem.minItemCount:sliceText[Chars,1]|DATA.creativeCopy.count|2", 1),
            ("DATA.creativeCopy.count:sliceText[Chars,1]|DATA.catalogItem.minItemCount|2", 1),
            ("STATE.IndicatorPosition:sliceText[Chars,1]|STATE.TotalOffers|2", 1),
            ("STATE.TotalOffers:sliceText[Chars,1]|DATA.catalogItem.maxItemCount|2", 3)
        ]
        for (chain, expected) in cases {
            assertNumeric(chain, equals: expected, context: context)
        }
    }

    func test_numericPredicatesKeepEarlierPlainAlternatives() throws {
        let context = try makeContext()
        let cases = [
            ("DATA.catalogItem.minItemCount|DATA.creativeCopy.count:sliceText[Chars,1]|2", 123),
            ("DATA.creativeCopy.count|STATE.IndicatorPosition:sliceText[Chars,1]|2", 123),
            ("STATE.IndicatorPosition|DATA.catalogItem.minItemCount:sliceText[Chars,1]|2", 12)
        ]
        for (chain, expected) in cases {
            assertNumeric(chain, equals: expected, context: context)
        }
    }

    func test_numericPredicatesConvertExpandedTextWithoutFallback() throws {
        let context = try makeContext()
        for (key, expected) in [("DATA.catalogItem.minItemCount", 1), ("DATA.creativeCopy.count", 1),
                                ("DATA.creativeCopy.mixed", 7), ("STATE.IndicatorPosition", 1), ("STATE.TotalOffers", 3)] {
            assertNumeric("\(key):sliceText[Chars,1]", equals: expected, context: context)
        }
    }

    func test_numericPredicatesUseLaterValuesAfterMissingOrInvalidSource() throws {
        let context = try makeContext()
        let cases = [
            ("DATA.catalogItem.missing|DATA.creativeCopy.count:sliceText[Chars,1]|2", 1),
            ("DATA.creativeCopy.missing:sliceText[Chars,1]|2", 2),
            ("DATA.catalogItem.minItemCount:unknown[]|2", 2),
            ("STATE.IndicatorPosition:unknown[]|2", 2),
            ("DATA.creativeCopy.count:unknown[]|DATA.catalogItem.minItemCount:sliceText[Chars,2]|2", 12)
        ]
        for (chain, expected) in cases {
            assertNumeric(chain, equals: expected, context: context)
        }
    }

    func test_plainNumericValuesAndFallbacksAreUnchanged() throws {
        let context = try makeContext()
        for (chain, expected) in [("DATA.catalogItem.minItemCount", 123), ("DATA.creativeCopy.count", 123),
                                  ("STATE.IndicatorPosition", 12), ("STATE.TotalOffers", 34),
                                  ("DATA.creativeCopy.missing|2", 2), ("2", 2)] {
            assertNumeric(chain, equals: expected, context: context)
        }
        let resolver = PlaceholderPredicateResolver()
        XCTAssertEqual(resolver.resolveDecimal(placeholder: "%^DATA.creativeCopy.decimal^%", context: context),
                       Decimal(string: "12.75"))
        XCTAssertEqual(resolver.resolveInt(placeholder: "%^DATA.creativeCopy.decimal^%", context: context), 12)
    }

    func test_stringAndTextLengthConsumersStillApplyTextOperations() throws {
        let context = try makeContext()
        let resolver = PlaceholderPredicateResolver()
        let cases = [
            ("DATA.catalogItem.minItemCount:sliceText[Chars,1]|2", "1"),
            ("DATA.creativeCopy.count:sliceText[Chars,1]|2", "1"),
            ("DATA.creativeCopy.mixed:sliceText[Chars,1]|2", "7"),
            ("STATE.IndicatorPosition:sliceText[Chars,1]|2", "1"),
            ("STATE.TotalOffers:sliceText[Chars,1]|2", "3"),
            ("DATA.creativeCopy.text:sliceText[Chars,2]|fallback", "👩🏽‍🚀é"),
            ("DATA.creativeCopy.text:sliceText[Chars,0]|fallback", "")
        ]
        for (chain, expected) in cases {
            let placeholder = "%^\(chain)^%"
            XCTAssertEqual(resolver.resolveString(placeholder: placeholder, context: context), expected, chain)
            XCTAssertEqual(resolver.resolveTextLength(placeholder: placeholder, context: context), expected.count, chain)
        }
    }

    func test_directTypedIntegerExtractionStillRejectsTextOperations() throws {
        let context = try makeContext()
        XCTAssertThrowsError(try CatalogDataExtractor().extractDataRepresentedBy(
            Int.self, propertyChain: "DATA.catalogItem.minItemCount:sliceText[Chars,1]",
            responseKey: nil, from: context.activeCatalogItem
        ))
        XCTAssertThrowsError(try CreativeDataExtractor().extractDataRepresentedBy(
            Int.self, propertyChain: "DATA.creativeCopy.count:sliceText[Chars,1]",
            responseKey: nil, from: context.offers[context.currentOfferIndex]
        ))
    }

    private func assertNumeric(_ chain: String, equals expected: Int, context: PlaceholderResolutionContext,
                               file: StaticString = #filePath, line: UInt = #line) {
        let resolver = PlaceholderPredicateResolver()
        let placeholder = "%^\(chain)^%"
        XCTAssertEqual(resolver.resolveDecimal(placeholder: placeholder, context: context), Decimal(expected),
                       chain, file: file, line: line)
        XCTAssertEqual(resolver.resolveInt(placeholder: placeholder, context: context), expected,
                       chain, file: file, line: line)
    }

    private func makeContext() throws -> PlaceholderResolutionContext {
        let data = try JSONEncoder().encode(CatalogItem.mock())
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        fields["minItemCount"] = 123
        fields["maxItemCount"] = 456
        fields["preSelectedQuantity"] = 123
        let catalogItem = try JSONDecoder().decode(CatalogItem.self, from: JSONSerialization.data(withJSONObject: fields))
        let offer = OfferModel.mock(copy: ["count": "123", "decimal": "12.75", "mixed": "7 apples", "text": "👩🏽‍🚀éx"])
        return PlaceholderResolutionContext(offers: Array(repeating: Optional(offer), count: 34), currentOfferIndex: 12,
                                            activeCatalogItem: catalogItem)
    }
}
