import XCTest
@testable import RoktUXHelper

final class BNFTextOperationTests: XCTestCase {
    func testSliceUsesCharacterBoundariesAt77_78_79() throws {
        for length in [77, 78, 79] {
            let value = String(repeating: "a", count: length)
            XCTAssertEqual(try BNFTextOperation("sliceText[Chars,78]").apply(to: value),
                           String(repeating: "a", count: min(length, 78)))
        }
    }

    func testSlicePreservesEmojiFlagsAndCombiningMarks() throws {
        for character in ["👨‍👩‍👧‍👦", "🇺🇸", "e\u{301}", "👍🏽", "क्‍ष"] {
            let prefix = String(repeating: "a", count: 77)
            let value = prefix + character + "z"
            let expected = String(value.prefix(78))
            XCTAssertEqual(try BNFTextOperation("sliceText[Chars,78]").apply(to: value), expected)
            XCTAssertEqual(expected.count, 78)
        }
    }

    func testZeroEmptyAndLengthBeyondContent() throws {
        XCTAssertEqual(try BNFTextOperation("sliceText[Chars,0]").apply(to: "abc"), "")
        XCTAssertEqual(try BNFTextOperation("sliceText[Chars,78]").apply(to: ""), "")
        XCTAssertEqual(try BNFTextOperation("sliceText[Chars,78]").apply(to: "short"), "short")
        XCTAssertEqual(try BNFTextOperation("sliceText[Chars,\(Int.max)]").apply(to: "short"), "short")
    }

    func testParserKeepsOperationsOnEachAlternativeAndPreservesLiteralFallback() throws {
        let parsed = PropertyChainDataParser().parse(propertyChain:
            "%^DATA.creativeCopy.title:sliceText[Chars,4]:sliceText[Chars,2]|DATA.creativeCopy.other:sliceText[Chars,3]|fallback^%")
        XCTAssertEqual(parsed.parseableChains.map(\.key), ["title", "other"])
        XCTAssertEqual(parsed.parseableChains[0].textOperations, [.sliceCharacters(4), .sliceCharacters(2)])
        XCTAssertEqual(parsed.parseableChains[1].textOperations, [.sliceCharacters(3)])
        XCTAssertEqual(parsed.defaultValue, "fallback")
        XCTAssertEqual(try parsed.parseableChains[0].applyingTextOperations(to: "abcdef"), "ab")
    }

    func testMalformedAndUnsupportedOperationsAreRejected() {
        let expressions = [
            "sliceText", "sliceText[]", "sliceText[Chars]", "sliceText[Chars,]", "sliceText[Chars,1,2]",
            "sliceText[Words,2]", "sliceText[chars,2]", "sliceText[ Chars,2]", "sliceText[Chars, 2]",
            "sliceText[Chars,-1]", "sliceText[Chars,+1]", "sliceText[Chars,1.5]", "sliceText[Chars,NaN]",
            "sliceText[Chars,Infinity]", "sliceText[Chars,9999999999999999999999999]",
            "sliceText[Chars,2", "sliceText[Chars,2]]", "sliceText[Chars,٢]", "unknown[Chars,2]"
        ]
        for expression in expressions {
            XCTAssertEqual(BNFTextOperation(expression), .invalid, expression)
            XCTAssertFalse(PlaceholderValidator().isValid(data: "DATA.creativeCopy.copy:" + expression), expression)
            XCTAssertThrowsError(try BNFTextOperation(expression).apply(to: "text"), expression)
        }
    }

    func testRecognizesValidOperatorTokensAndExistingPlainPlaceholders() {
        let validator = PlaceholderValidator()
        for value in ["DATA.creativeCopy.copy", "DATA.creativeCopy.copy:sliceText[Chars,78]",
                      "DATA.creativeCopy.missing:sliceText[Chars,2]|fallback",
                      "DATA.creativeCopy.missing:sliceText[Chars,2]|"] {
            XCTAssertTrue(validator.isValid(data: value), value)
        }
    }

    func testDeferredRuntimeAndStateResolutionApplyOperations() {
        let token = "%^DATA.catalogRuntime.title:sliceText[Chars,2]|fallback^%"
        XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: token, catalogRuntimeData: ["title": "👩🏽‍🚀abc"]),
                       "👩🏽‍🚀a")
        XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: token, catalogRuntimeData: [:]), "fallback")
        XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: token, catalogRuntimeData: ["title": ""]), "fallback")
        XCTAssertEqual(TextComponentBNFHelper.replaceStates("%^STATE.TotalOffers:sliceText[Chars,1]^%",
                                                            currentOffer: "1", totalOffers: "12"), "1")
    }

    func testUnclaimedOperatorPlaceholdersKeepExistingFallbackRules() {
        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: "%^DATA.creativeCopy.missing:sliceText[Chars,2]|fallback^%"),
                       "fallback")
        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: "%^DATA.creativeCopy.missing:sliceText[Chars,2]|^%"), "")
        XCTAssertNil(OrphanedPlaceholderResolver.resolve(text: "%^DATA.creativeCopy.missing:sliceText[Chars,2]^%"))
    }
}
