import XCTest
@testable import RoktUXHelper

final class BNFTokenScannerTests: XCTestCase {

    private let regex = try! NSRegularExpression(pattern: BNFPlaceholder.deferredExpression)

    private func scan(_ text: String) -> [(chain: String, span: String)] {
        BNFTokenScanner.tokens(in: text, matching: regex).map {
            ($0.chain, (text as NSString).substring(with: $0.tokenRange))
        }
    }

    // MARK: - Spans cover the delimiters

    func test_tokenRangeCoversTheDelimiters() {
        let scanned = scan("Subtotal: %^DATA.catalogRuntime.subtotal | --^% today")

        XCTAssertEqual(scanned.map(\.chain), ["DATA.catalogRuntime.subtotal | --"])
        XCTAssertEqual(scanned.map(\.span), ["%^DATA.catalogRuntime.subtotal | --^%"])
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
    }

    func test_adjacentTokensSharingADelimiterKeepOnlyTheFirst() {
        // `^%^` is one `%` short of two complete delimiters. The lookarounds match twice anyway,
        // over spans that share that character; only the first is a token, the rest is literal.
        let scanned = scan("%^DATA.creativeLink.a | A^%^DATA.creativeLink.b | B^%")

        XCTAssertEqual(scanned.map(\.chain), ["DATA.creativeLink.a | A"])
        XCTAssertEqual(scanned.map(\.span), ["%^DATA.creativeLink.a | A^%"])
    }

    func test_chainOfSharedDelimitersAlternatesBetweenTokenAndLiteral() {
        let scanned = scan("%^a^%^b^%^c^%")

        XCTAssertEqual(scanned.map(\.chain), ["a", "c"])
        XCTAssertEqual(scanned.map(\.span), ["%^a^%", "%^c^%"])
    }

    func test_emptyChainSharingADelimiterKeepsOnlyTheFirst() {
        XCTAssertEqual(scan("%^^%^^%").map(\.span), ["%^^%"])
    }

    // MARK: - Nothing to scan

    func test_textWithoutPlaceholdersReturnsNoTokens() {
        XCTAssertTrue(scan("Plain marketing copy with no placeholders.").isEmpty)
    }

    func test_unclosedDelimiterReturnsNoTokens() {
        XCTAssertTrue(scan("%^DATA.creativeLink.foo").isEmpty)
    }
}
