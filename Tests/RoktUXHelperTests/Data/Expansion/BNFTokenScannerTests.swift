import XCTest
@testable import RoktUXHelper

final class BNFTokenScannerTests: XCTestCase {

    private let regex = try! NSRegularExpression(pattern: BNFPlaceholder.deferredExpression)

    private func scan(_ text: String) -> [(chain: String, span: String, isSpliceable: Bool)] {
        BNFTokenScanner.tokens(in: text, matching: regex).map {
            ($0.chain, (text as NSString).substring(with: $0.tokenRange), $0.isSpliceable)
        }
    }

    // MARK: - Spans cover the delimiters

    func test_tokenRangeCoversTheDelimiters() {
        let scanned = scan("Subtotal: %^DATA.catalogRuntime.subtotal | --^% today")

        XCTAssertEqual(scanned.map(\.chain), ["DATA.catalogRuntime.subtotal | --"])
        XCTAssertEqual(scanned.map(\.span), ["%^DATA.catalogRuntime.subtotal | --^%"])
        XCTAssertEqual(scanned.map(\.isSpliceable), [true])
    }

    func test_tokenRangesAreUTF16OffsetsPastMultiScalarCharacters() {
        // An emoji and a combining mark either side of the token: the span must still line up.
        let text = "👩🏽‍🚀 %^DATA.creativeLink.foo | a^% e\u{301}"

        XCTAssertEqual(scan(text).map(\.span), ["%^DATA.creativeLink.foo | a^%"])
    }

    // MARK: - Adjacent tokens

    func test_adjacentTokensWithTheirOwnDelimitersAreBothReturned() {
        let scanned = scan("%^DATA.creativeLink.a | A^%%^DATA.creativeLink.b | B^%")

        XCTAssertEqual(scanned.map(\.chain), ["DATA.creativeLink.a | A", "DATA.creativeLink.b | B"])
        XCTAssertEqual(scanned.map(\.isSpliceable), [true, true])
    }

    func test_adjacentTokensSharingADelimiter_secondIsReturnedButNotSpliceable() {
        // `^%^` is one `%` short of two complete delimiters. The lookarounds match twice anyway,
        // over spans that share that character. Both chains are real placeholders and both are
        // returned — a caller must still be able to fail loud on a mandatory second token — but
        // only the first is safe to splice; the second's span stays literal text if it is spliced.
        let scanned = scan("%^DATA.creativeLink.a | A^%^DATA.creativeLink.b | B^%")

        XCTAssertEqual(scanned.map(\.chain), ["DATA.creativeLink.a | A", "DATA.creativeLink.b | B"])
        XCTAssertEqual(scanned.map(\.span), ["%^DATA.creativeLink.a | A^%", "%^DATA.creativeLink.b | B^%"])
        XCTAssertEqual(scanned.map(\.isSpliceable), [true, false])
    }

    func test_chainOfSharedDelimitersAlternatesSpliceableAndNot() {
        let scanned = scan("%^a^%^b^%^c^%")

        XCTAssertEqual(scanned.map(\.chain), ["a", "b", "c"])
        XCTAssertEqual(scanned.map(\.isSpliceable), [true, false, true])
    }

    func test_emptyChainSharingADelimiter_bothReturnedOnlyFirstSpliceable() {
        let scanned = scan("%^^%^^%")

        XCTAssertEqual(scanned.map(\.span), ["%^^%", "%^^%"])
        XCTAssertEqual(scanned.map(\.isSpliceable), [true, false])
    }

    // MARK: - Nothing to scan

    func test_textWithoutPlaceholdersReturnsNoTokens() {
        XCTAssertTrue(scan("Plain marketing copy with no placeholders.").isEmpty)
    }

    func test_unclosedDelimiterReturnsNoTokens() {
        XCTAssertTrue(scan("%^DATA.creativeLink.foo").isEmpty)
    }
}
