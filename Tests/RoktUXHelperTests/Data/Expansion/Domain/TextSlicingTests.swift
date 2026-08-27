import XCTest
@testable import RoktUXHelper

final class TextSlicingTests: XCTestCase {
    func testCreativeMapperSlicesWithinSurroundingCopy() {
        for length in [77, 78, 79] {
            let model = text("Before %^DATA.creativeCopy.copy:sliceText[Chars,78]^% after")
            CreativeMapper().map(consumer: .basicText(model),
                                 context: .generic(offer(copy: String(repeating: "a", count: length))))
            XCTAssertEqual(model.boundValue, "Before " + String(repeating: "a", count: min(length, 78)) + " after")
        }
    }

    func testCreativeFallbackAlternativesAndLiteralAreNotSlicedByPreviousAlternative() throws {
        let extractor = CreativeDataExtractor()
        let data = offer(copy: "abcdef")
        XCTAssertEqual(try extractor.extractDataRepresentedBy(String.self,
                                                              propertyChain: "DATA.creativeCopy.missing:sliceText[Chars,2]|DATA.creativeCopy.copy:sliceText[Chars,3]|fallback",
                                                              responseKey: nil, from: data), .value("abc"))
        XCTAssertEqual(try extractor.extractDataRepresentedBy(String.self,
                                                              propertyChain: "DATA.creativeCopy.missing:sliceText[Chars,2]|fallback",
                                                              responseKey: nil, from: data), .value("fallback"))
        XCTAssertEqual(try extractor.extractDataRepresentedBy(String.self,
                                                              propertyChain: "DATA.creativeCopy.copy:sliceText[Chars,2]|fallback",
                                                              responseKey: nil, from: offer(copy: "")), .value("fallback"))
        XCTAssertEqual(try extractor.extractDataRepresentedBy(String.self,
                                                              propertyChain: "DATA.creativeCopy.missing:sliceText[Chars,2]|",
                                                              responseKey: nil, from: data), .value(""))
    }

    func testMalformedOperationsDoNotLeakTheirSyntaxIntoRenderedCopy() {
        for operation in ["sliceText[Chars,-1]", "sliceText[Chars,NaN]", "sliceText[Chars,2", "sliceText[Chars,2]:unknown[]"] {
            let model = text("Before %^DATA.creativeCopy.copy:\(operation)^% after")
            CreativeMapper().map(consumer: .basicText(model), context: .generic(offer(copy: "abcdef")))
            XCTAssertEqual(model.boundValue, "", operation)
            XCTAssertThrowsError(try CreativeDataExtractor().extractDataRepresentedBy(String.self,
                                                                                      propertyChain: "DATA.creativeCopy.copy:\(operation)",
                                                                                      responseKey: nil,
                                                                                      from: offer(copy: "abcdef")))
        }
    }

    func testSliceAndExistingLengthPredicateAgreeOnUnicode() throws {
        let value = String(repeating: "a", count: 77) + "👩🏽‍🚀" + "z"
        let data = offer(copy: value)
        let context = PlaceholderResolutionContext(offers: [data], currentOfferIndex: 0, activeCatalogItem: nil)
        let resolver = PlaceholderPredicateResolver()
        XCTAssertEqual(resolver.resolveTextLength(placeholder: "%^DATA.creativeCopy.copy^%", context: context), 79)
        let model = text("%^DATA.creativeCopy.copy:sliceText[Chars,78]^%")
        CreativeMapper().map(consumer: .basicText(model), context: .generic(data))
        XCTAssertEqual(model.boundValue, String(value.dropLast()))
        XCTAssertEqual(model.boundValue.count, 78)
        XCTAssertEqual(resolver.resolveTextLength(placeholder: "%^DATA.creativeCopy.copy:sliceText[Chars,78]^%",
                                                  context: context), 78)
    }

    func testMissingMandatoryValueKeepsExistingEmptyLineBehavior() {
        let model = text("Before %^DATA.creativeCopy.missing:sliceText[Chars,78]^% after")
        CreativeMapper().map(consumer: .basicText(model), context: .generic(offer(copy: "text")))
        XCTAssertEqual(model.boundValue, "")
    }

    func testCatalogExtractionSlicesItsResolvedValue() throws {
        let result = try CatalogDataExtractor().extractDataRepresentedBy(String.self,
                                                                         propertyChain: "DATA.catalogItem.price:sliceText[Chars,2]",
                                                                         responseKey: nil,
                                                                         from: CatalogItem.mock(catalogItemId: "item-1",
                                                                                                images: nil))
        XCTAssertEqual(result, .value("14"))
    }

    func testTransactionExtractionAndMapperPreserveLiteralFallbacks() throws {
        let transaction = TransactionData(shippingAddress: nil, billingAddress: nil, paymentType: nil,
                                          supportedPaymentMethods: nil, isPartnerManagedPurchase: false,
                                          partnerPaymentReference: nil, confirmationRef: nil,
                                          metadata: ["summary": "abcdef"])
        let model = text("%^DATA.transactionData.metadata.summary:sliceText[Chars,3]|fallback^%")
        TransactionDataMapper().map(consumer: .basicText(model), context: transaction)
        XCTAssertEqual(model.boundValue, "abc")
        XCTAssertEqual(try TransactionDataExtractor().extractDataRepresentedBy(String.self,
                                                                               propertyChain: "DATA.transactionData.metadata.missing:sliceText[Chars,2]|fallback",
                                                                               responseKey: nil,
                                                                               from: transaction), .value("fallback"))
    }

    func testOperatorFallbackCanContainLocalizedPunctuation() throws {
        XCTAssertEqual(try CreativeDataExtractor().extractDataRepresentedBy(String.self,
                                                                            propertyChain: "DATA.creativeCopy.missing:sliceText[Chars,2]|Détails…",
                                                                            responseKey: nil,
                                                                            from: offer(copy: "")), .value("Détails…"))
    }

    func testTextOperationsRejectNonTextResultTypesWithoutCasting() {
        XCTAssertThrowsError(try CatalogDataExtractor().extractDataRepresentedBy(Int.self,
                                                                                 propertyChain: "DATA.catalogItem.price:sliceText[Chars,2]",
                                                                                 responseKey: nil,
                                                                                 from: CatalogItem.mock(catalogItemId: "item-1",
                                                                                                        images: nil)))
    }

    private func text(_ value: String) -> BasicTextViewModel {
        BasicTextViewModel(value: value, defaultStyle: nil, pressedStyle: nil, hoveredStyle: nil, disabledStyle: nil,
                           layoutState: nil, diagnosticService: nil)
    }

    private func offer(copy: String) -> OfferModel {
        OfferModel(campaignId: nil,
                   creative: CreativeModel(referralCreativeId: "creative", instanceGuid: "instance",
                                           copy: ["copy": copy], images: nil, links: nil,
                                           responseOptionsMap: nil, jwtToken: ""),
                   catalogItems: nil, catalogItemGroup: nil, transactionData: nil)
    }
}
