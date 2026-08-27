import XCTest
@testable import RoktUXHelper

final class CatalogRuntimePlaceholderResolverTests: XCTestCase {

    func test_invalidMandatoryOperationEmptiesTheLineBeforeAndAfterRuntimeDataArrives() {
        for operation in ["sliceText[Chars,-1]", "sliceText[Chars,NaN]", "sliceText[Chars,2", "unknown[]"] {
            let text = "Before %^DATA.catalogRuntime.title:\(operation)^% after"
            for data: [String: String]? in [nil, [:], ["title": ""], ["title": "abcdef"]] {
                XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: text, catalogRuntimeData: data), "", operation)
            }
        }
    }

    func test_invalidOperationUsesItsLiteralOrEmptyDefault() {
        for fallback in ["Détails…", ""] {
            let text = "Before %^DATA.catalogRuntime.title:sliceText[Chars,-1]|\(fallback)^% after"
            for data: [String: String]? in [nil, ["title": "abcdef"]] {
                XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: text, catalogRuntimeData: data),
                               "Before \(fallback) after")
            }
        }
    }

    func test_invalidRuntimeAlternativeCanFallThroughToAValidAlternative() {
        let text = "%^DATA.catalogRuntime.first:sliceText[Chars,-1]|DATA.catalogRuntime.second:sliceText[Chars,2]|fallback^%"
        XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: text,
                                                                 catalogRuntimeData: ["first": "abc", "second": "👩🏽‍🚀e\u{301}z"]),
                       "👩🏽‍🚀e\u{301}")
        XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: text, catalogRuntimeData: ["first": "abc"]),
                       "fallback")
    }

    func test_validFirstAlternativeDoesNotEvaluateAnUnusedInvalidOperation() {
        let text = "%^DATA.catalogRuntime.first:sliceText[Chars,2]|DATA.catalogRuntime.second:unknown[]^%"
        XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: text,
                                                                 catalogRuntimeData: ["first": "abc", "second": "def"]), "ab")
    }

    func test_invalidMandatoryOperationStillEmptiesCopyContainingOtherResolvedTokens() {
        let text = "👩🏽‍🚀 %^DATA.catalogRuntime.first^% / %^DATA.catalogRuntime.second:sliceText[Chars,-1]^% / %^DATA.catalogRuntime.first^%"
        XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: text,
                                                                 catalogRuntimeData: ["first": "copy", "second": "value"]), "")
    }

    func test_validMandatoryRuntimeOperationRemainsDeferredUntilDataArrives() {
        let text = "Before %^DATA.catalogRuntime.title:sliceText[Chars,2]^% after"
        for data: [String: String]? in [nil, [:], ["title": ""]] {
            XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: text, catalogRuntimeData: data), text)
        }
        XCTAssertEqual(CatalogRuntimePlaceholderResolver.resolve(text: text, catalogRuntimeData: ["title": "abcdef"]),
                       "Before ab after")
    }

    // MARK: - Single occurrence (baseline)

    func test_singleOccurrence_resolvesFromRuntimeData() {
        let text = "Subtotal: %^DATA.catalogRuntime.subtotal | --^%"

        let result = CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: ["subtotal": "$24.00"]
        )

        XCTAssertEqual(result, "Subtotal: $24.00")
    }

    func test_singleOccurrence_fallsBackToDefault_whenDataMissing() {
        let text = "Subtotal: %^DATA.catalogRuntime.subtotal | --^%"

        let result = CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: nil
        )

        XCTAssertEqual(result, "Subtotal: --")
    }

    // MARK: - Duplicate occurrences (regression: positional vs global-search replace)

    func test_duplicateOccurrences_bothResolve() {
        // Same token used twice in one string. Global `result.range(of:)` replacement
        // would resolve only the first; the second would leak raw `%^…^%` syntax.
        let text = "A %^DATA.catalogRuntime.x^% B %^DATA.catalogRuntime.x^% C"

        let result = CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: ["x": "foo"]
        )

        XCTAssertEqual(result, "A foo B foo C")
    }

    func test_threeOccurrences_allResolve() {
        let text = "%^DATA.catalogRuntime.x^%/%^DATA.catalogRuntime.x^%/%^DATA.catalogRuntime.x^%"

        let result = CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: ["x": "1"]
        )

        XCTAssertEqual(result, "1/1/1")
    }

    func test_duplicateOccurrences_bothFallBackIndependently() {
        // Both occurrences miss the runtime map → both resolve to the `--` default,
        // not just the first.
        let text = "Subtotal: %^DATA.catalogRuntime.subtotal | --^% / Total: %^DATA.catalogRuntime.subtotal | --^%"

        let result = CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: nil
        )

        XCTAssertEqual(result, "Subtotal: -- / Total: --")
    }

    // MARK: - Mixed namespaces — non-runtime tokens pass through

    func test_nonRuntimePlaceholder_passesThroughUntouched() {
        // The resolver only touches placeholders containing DATA.catalogRuntime.*; other
        // namespaces are left for their own mappers / the orphan finalizer.
        let text = "Hi %^DATA.creativeCopy.name | friend^%"

        let result = CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: ["unrelated": "value"]
        )

        XCTAssertEqual(result, text)
    }

    func test_runtimeAndNonRuntime_inSameString_onlyRuntimeResolves() {
        let text = "%^DATA.creativeCopy.name | friend^% paid %^DATA.catalogRuntime.total | --^%"

        let result = CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: ["total": "$26.72"]
        )

        XCTAssertEqual(result, "%^DATA.creativeCopy.name | friend^% paid $26.72")
    }

    // MARK: - No placeholders → unchanged

    func test_textWithoutPlaceholders_returnsUnchanged() {
        let text = "Plain marketing copy with no placeholders."

        let result = CatalogRuntimePlaceholderResolver.resolve(
            text: text,
            catalogRuntimeData: ["x": "y"]
        )

        XCTAssertEqual(result, text)
    }
}
