import XCTest
@testable import RoktUXHelper

final class OrphanedPlaceholderResolverTests: XCTestCase {

    // MARK: - Mandatory orphans (no `|` default) → fail-loud (nil return)

    func test_mandatoryOrphan_inUnclaimedNamespace_returnsNil() {
        // Creative-link placeholder that no mapper resolved AND no `|` fallback.
        let text = "%^DATA.creativeLink.termsAndConditions^%"

        XCTAssertNil(OrphanedPlaceholderResolver.resolve(text: text))
    }

    func test_mandatoryOrphan_mixedWithResolvedText_returnsNil() {
        // Even when the mandatory orphan sits next to plain text, the whole line fails.
        let text = "Read our terms here: %^DATA.creativeLink.termsAndConditions^%"

        XCTAssertNil(OrphanedPlaceholderResolver.resolve(text: text))
    }

    // MARK: - Optional orphans (with `|` default) → fallback substituted

    func test_optionalOrphan_substitutesDefaultLiteral() {
        let text = "%^DATA.creativeLink.foo | Read terms^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), "Read terms")
    }

    func test_optionalOrphan_withEmptyDefault_substitutesEmptyString() {
        // `| ^%` ends with the alternative separator → defaultValue is "".
        let text = "Header%^DATA.creativeLink.foo|^%Footer"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), "HeaderFooter")
    }

    func test_optionalOrphan_keepsSurroundingText() {
        let text = "Subtotal: %^DATA.creativeLink.foo | $0.00^% (estimated)"

        XCTAssertEqual(
            OrphanedPlaceholderResolver.resolve(text: text),
            "Subtotal: $0.00 (estimated)"
        )
    }

    // MARK: - Deferred namespaces → left untouched

    func test_catalogRuntimePlaceholder_isDeferred_andPreserved() {
        // catalogRuntime is resolved reactively when the host pushes data; resolver must
        // not zero the line just because runtime data hasn't arrived yet.
        let text = "Subtotal: %^DATA.catalogRuntime.subtotal | --^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), text)
    }

    func test_catalogRuntimeMandatoryPlaceholder_isDeferred_notZeroed() {
        // Even without `|`, catalogRuntime placeholders defer to runtime resolution
        // rather than failing the line at finalize time.
        let text = "Total: %^DATA.catalogRuntime.total^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), text)
    }

    func test_statePlaceholder_isDeferred_andPreserved() {
        // STATE.IndicatorPosition is resolved at render time inside BasicTextViewModel;
        // resolver must not zero or substitute it.
        let text = "Page %^STATE.IndicatorPosition^% of %^STATE.TotalOffers^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), text)
    }

    // MARK: - No placeholders → unchanged

    func test_textWithoutPlaceholders_returnsUnchanged() {
        let text = "Plain marketing copy with no placeholders."

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), text)
    }

    // MARK: - Multiple orphans

    func test_multipleOptionalOrphans_allSubstituted() {
        let text = "%^DATA.creativeCopy.greeting | Hi^%, %^DATA.creativeLink.tnc | Read terms^%"

        XCTAssertEqual(
            OrphanedPlaceholderResolver.resolve(text: text),
            "Hi, Read terms"
        )
    }

    func test_oneMandatoryOrphan_amongOptionals_zeroesLine() {
        // Optionals would substitute, but the single mandatory orphan still fails the line.
        let text = "%^DATA.creativeLink.foo | fallback^% and %^DATA.creativeLink.bar^%"

        XCTAssertNil(OrphanedPlaceholderResolver.resolve(text: text))
    }

    func test_duplicateOptionalOrphans_bothFallbacksApply() {
        // Same token appears twice. A global `result.range(of:)` replacement would only
        // substitute the first occurrence; the second would leak raw `%^…^%` syntax.
        let text = "%^DATA.creativeLink.foo | a^% / %^DATA.creativeLink.foo | a^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), "a / a")
    }

    func test_mixedDuplicateAndUniqueOrphans_allSubstituted() {
        let text = "%^DATA.creativeLink.foo | A^% %^DATA.creativeLink.bar | B^% %^DATA.creativeLink.foo | A^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), "A B A")
    }

    // MARK: - Adjacent orphans sharing a delimiter (regression: index past endIndex)

    func test_adjacentOrphansSharingADelimiter_resolveTheFirst_andKeepTheRestLiteral() {
        // `^%^` closes one token and opens the next off the same `%`, so the pattern matches
        // twice over overlapping spans. Substituting both used to run the second replacement
        // over a range the first had already shortened, trapping on a String index.
        let text = "%^DATA.creativeLink.a|^%^DATA.creativeLink.b|^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), "^DATA.creativeLink.b|^%")
    }

    func test_adjacentOrphansSharingADelimiter_withSurroundingCopy() {
        let text = "Head %^DATA.creativeLink.a | A^%^DATA.creativeLink.b | B^% tail"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), "Head A^DATA.creativeLink.b | B^% tail")
    }

    func test_threeOrphansSharingDelimiters_alternateBetweenSubstitutedAndLiteral() {
        let text = "%^DATA.creativeLink.a|^%^DATA.creativeLink.b|^%^DATA.creativeLink.c|^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), "^DATA.creativeLink.b|^")
    }

    func test_adjacentOrphansWithTheirOwnDelimiters_bothSubstituted() {
        // One `%` more than the shared-delimiter case: two complete tokens, both resolve.
        let text = "%^DATA.creativeLink.a | A^%%^DATA.creativeLink.b | B^%"

        XCTAssertEqual(OrphanedPlaceholderResolver.resolve(text: text), "AB")
    }

    func test_mandatoryOrphanSharingADelimiterWithAnOptionalOne_stillZeroesLine() {
        let text = "%^DATA.creativeLink.a^%^DATA.creativeLink.b|^%"

        XCTAssertNil(OrphanedPlaceholderResolver.resolve(text: text))
    }

    // Regression: the mandatory placeholder here is the *second* of an overlapping pair — the
    // one BNFTokenScanner marks `isSpliceable == false`. Before the fix, that meant its chain was
    // never even evaluated, so a mandatory-and-unresolved placeholder silently failed to zero the
    // line as long as the placeholder sharing its delimiter happened to resolve.
    func test_mandatoryOrphanAsTheOverlappingSecondToken_stillZeroesLine() {
        let text = "%^DATA.creativeLink.a|^%^DATA.creativeLink.b^%"

        XCTAssertNil(OrphanedPlaceholderResolver.resolve(text: text))
    }

    // Note: Codex flagged a related concern (a replacement starting with a Unicode combining
    // mark can merge into a preceding token's closing `%` and invalidate that token's stored
    // range). It cannot reach this resolver in practice — every value this resolver splices in
    // is `parsed.defaultValue`, always drawn from the matched chain's own grammar-constrained
    // characters (`a-zA-Z0-9 .|_$-`) or the empty string, none of which can begin with a
    // combining mark. See `CatalogRuntimePlaceholderResolverTests` for the reachable case: its
    // replacement values come from an arbitrary host-supplied dictionary, not from the grammar.
    // The splice here was still switched to NSMutableString to match, since it is strictly
    // simpler than converting NSRange to a Swift String.Index and carries the same guarantee.

    // MARK: - Mixed: deferred + orphan

    func test_deferredAlongsideOptionalOrphan_substitutesOptional_keepsDeferred() {
        let text = "%^DATA.creativeLink.foo | --^% / %^DATA.catalogRuntime.subtotal^%"

        XCTAssertEqual(
            OrphanedPlaceholderResolver.resolve(text: text),
            "-- / %^DATA.catalogRuntime.subtotal^%"
        )
    }

    func test_deferredAlongsideMandatoryOrphan_stillZeroesLine() {
        let text = "%^DATA.creativeLink.foo^% / %^DATA.catalogRuntime.subtotal^%"

        XCTAssertNil(OrphanedPlaceholderResolver.resolve(text: text))
    }
}
