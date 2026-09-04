import XCTest
@testable import RoktUXHelper

final class TextOperationAlternativeTests: XCTestCase {
    func test_creativeOperationsAreEvaluatedOnlyForTheSelectedAlternative() throws {
        for (chain, expected) in alternatives(namespace: "DATA.creativeCopy", key: "copy") {
            XCTAssertEqual(try CreativeDataExtractor().extractDataRepresentedBy(String.self,
                                                                                propertyChain: chain,
                                                                                responseKey: nil,
                                                                                from: offer), .value(expected), chain)
        }
    }

    func test_catalogOperationsAreEvaluatedOnlyForTheSelectedAlternative() throws {
        for (chain, expected) in alternatives(namespace: "DATA.catalogItem", key: "catalogItemId") {
            XCTAssertEqual(try CatalogDataExtractor().extractDataRepresentedBy(String.self,
                                                                               propertyChain: chain,
                                                                               responseKey: nil,
                                                                               from: catalogItem), .value(expected), chain)
        }
    }

    func test_transactionOperationsAreEvaluatedOnlyForTheSelectedAlternative() throws {
        let transaction = TransactionData(shippingAddress: nil, billingAddress: nil, paymentType: nil,
                                          supportedPaymentMethods: nil, isPartnerManagedPurchase: false,
                                          partnerPaymentReference: nil, confirmationRef: nil,
                                          metadata: ["summary": "abcdef"])
        for (chain, expected) in alternatives(namespace: "DATA.transactionData", key: "metadata.summary") {
            XCTAssertEqual(try TransactionDataExtractor().extractDataRepresentedBy(String.self,
                                                                                   propertyChain: chain,
                                                                                   responseKey: nil,
                                                                                   from: transaction), .value(expected), chain)
        }
    }

    func test_unusedTextOperationsDoNotRejectSelectedNumericOrBooleanValues() throws {
        for operation in ["sliceText[Chars,2]", "unknown[]"] {
            XCTAssertThrowsError(try CreativeDataExtractor().extractDataRepresentedBy(Int.self,
                                                                                      propertyChain: "DATA.creativeCopy.copy:\(operation)|fallback",
                                                                                      responseKey: nil, from: offer))
            XCTAssertThrowsError(try CreativeDataExtractor().extractDataRepresentedBy(Int.self,
                                                                                      propertyChain: "DATA.creativeCopy.copy|DATA.creativeCopy.copy:\(operation)",
                                                                                      responseKey: nil, from: offer))
        }
        let catalogCases = [
            "DATA.catalogItem.minItemCount|DATA.catalogItem.title:unknown[]",
            "DATA.catalogItem.title:sliceText[Chars,2]|DATA.catalogItem.minItemCount"
        ]
        for chain in catalogCases {
            XCTAssertEqual(try CatalogDataExtractor().extractDataRepresentedBy(Int.self, propertyChain: chain,
                                                                               responseKey: nil, from: catalogItem), .value(1))
        }
        XCTAssertThrowsError(try CatalogDataExtractor().extractDataRepresentedBy(Int.self,
                                                                                 propertyChain: "DATA.catalogItem.missing:sliceText[Chars,2]|fallback",
                                                                                 responseKey: nil, from: catalogItem))
        let transaction = TransactionData(shippingAddress: nil, billingAddress: nil, paymentType: nil,
                                          supportedPaymentMethods: nil, isPartnerManagedPurchase: false,
                                          partnerPaymentReference: nil, confirmationRef: nil,
                                          metadata: ["summary": "abcdef"])
        let transactionCases = [
            "DATA.transactionData.isPartnerManagedPurchase|DATA.transactionData.metadata.summary:unknown[]",
            "DATA.transactionData.metadata.summary:sliceText[Chars,2]|DATA.transactionData.isPartnerManagedPurchase"
        ]
        for chain in transactionCases {
            XCTAssertEqual(try TransactionDataExtractor().extractDataRepresentedBy(Bool.self, propertyChain: chain,
                                                                                   responseKey: nil, from: transaction),
                           .value(false))
        }
        XCTAssertThrowsError(try TransactionDataExtractor().extractDataRepresentedBy(Bool.self,
                                                                                     propertyChain: "DATA.transactionData.metadata.missing:sliceText[Chars,2]|fallback",
                                                                                     responseKey: nil, from: transaction))
    }

    func test_predicateOperationsContinueAfterAnInvalidOrMissingAlternative() {
        let context = PlaceholderResolutionContext(offers: [offer], currentOfferIndex: 0,
                                                   activeCatalogItem: catalogItem)
        let resolver = PlaceholderPredicateResolver()
        for (namespace, key) in [("DATA.creativeCopy", "copy"), ("DATA.catalogItem", "catalogItemId")] {
            for (chain, expected) in alternatives(namespace: namespace, key: key) {
                XCTAssertEqual(resolver.resolveString(placeholder: "%^\(chain)^%", context: context), expected, chain)
            }
        }
        XCTAssertEqual(resolver.resolveString(placeholder: "%^STATE.IndicatorPosition:unknown[]|STATE.TotalOffers^%",
                                              context: context), "1")
    }

    func test_stateOperationsContinueAfterAnInvalidAlternativeInPlainAndAttributedText() {
        let cases = [
            ("STATE.totalOffers:sliceText[Chars,1]|STATE.indicatorPosition:unknown[]", "4"),
            ("STATE.indicatorPosition:unknown[]|STATE.totalOffers:sliceText[Chars,1]|fallback", "4"),
            ("STATE.indicatorPosition:unknown[]|fallback", "fallback")
        ]
        for (chain, expected) in cases {
            let text = "Before %^\(chain)^% after"
            XCTAssertEqual(TextComponentBNFHelper.replaceStates(text, currentOffer: "23", totalOffers: "45"),
                           "Before \(expected) after", chain)
            XCTAssertEqual(TextComponentBNFHelper.replaceStates(NSAttributedString(string: text),
                                                                currentOffer: "23", totalOffers: "45").string,
                           "Before \(expected) after", chain)
        }
    }

    func test_predicateMissingValuesUseLaterAlternativesAndKeepMandatoryFailures() {
        let context = PlaceholderResolutionContext(offers: [offer], currentOfferIndex: 0, activeCatalogItem: catalogItem)
        let resolver = PlaceholderPredicateResolver()
        for namespace in ["DATA.creativeCopy", "DATA.catalogItem"] {
            XCTAssertEqual(resolver.resolveString(placeholder: "%^\(namespace).missing:sliceText[Chars,2]|fallback^%",
                                                  context: context), "fallback")
            XCTAssertNil(resolver.resolveString(placeholder: "%^\(namespace).missing:sliceText[Chars,2]^%", context: context))
        }
        let missingOffer = PlaceholderResolutionContext(offers: [nil], currentOfferIndex: 0, activeCatalogItem: catalogItem)
        XCTAssertEqual(resolver.resolveString(placeholder: "%^DATA.creativeCopy.copy|DATA.catalogItem.catalogItemId^%",
                                              context: missingOffer), "abcdef")
    }

    func test_predicateEmptyValuesAndZeroLengthSlicesDoNotUseFallbacks() {
        let resolver = PlaceholderPredicateResolver()
        let context = PlaceholderResolutionContext(offers: [offer], currentOfferIndex: 0,
                                                   activeCatalogItem: CatalogItem.mock(catalogItemId: "", images: nil))
        for chain in ["DATA.catalogItem.catalogItemId|fallback", "DATA.creativeCopy.copy:sliceText[Chars,0]|fallback"] {
            XCTAssertEqual(resolver.resolveString(placeholder: "%^\(chain)^%", context: context), "")
            XCTAssertEqual(resolver.resolveTextLength(placeholder: "%^\(chain)^%", context: context), 0)
        }
    }

    func test_predicateWithoutAResponseKeyUsesLaterAlternatives() {
        let context = PlaceholderResolutionContext(offers: [offer], currentOfferIndex: 0, activeCatalogItem: catalogItem)
        let cases = [("DATA.creativeCopy.copy:sliceText[Chars,3]", "abc"),
                     ("DATA.catalogItem.catalogItemId:sliceText[Chars,2]", "ab"), ("fallback", "fallback")]
        for (alternative, expected) in cases {
            XCTAssertEqual(PlaceholderPredicateResolver().resolveString(
                placeholder: "%^DATA.creativeResponse.shortLabel:sliceText[Chars,2]|\(alternative)^%", context: context
            ),
                           expected)
        }
    }

    func test_creativeLinkSlicesItsTitleWithoutTruncatingMarkupOrTheURL() throws {
        let extractor = CreativeDataExtractor()
        for (operation, title) in [("", "Privacy policy"), (":sliceText[Chars,3]", "Pri"),
                                   (":sliceText[Chars,0]", ""), (":sliceText[Chars,100]", "Privacy policy")] {
            let chain = "DATA.creativeLink.policy\(operation)"
            let expected = "<a href=\"https://example.com/privacy\" target=\"_blank\">\(title)</a>"
            XCTAssertEqual(try extractor.extractDataRepresentedBy(String.self, propertyChain: chain,
                                                                  responseKey: nil, from: offer), .value(expected))
            let context = PlaceholderResolutionContext(offers: [offer], currentOfferIndex: 0, activeCatalogItem: nil)
            XCTAssertEqual(PlaceholderPredicateResolver().resolveString(placeholder: "%^\(chain)^%", context: context),
                           expected)
        }
    }

    func test_creativeImageURLsAndTextKeepTheirExistingValueSemantics() throws {
        let extractor = CreativeDataExtractor()
        let cases = [("light", "https://example.com/image.png"), ("dark", "https://example.com/dark.png"),
                     ("title:sliceText[Chars,3]", "Ima"), ("alt:sliceText[Chars,3]", "Alt")]
        for (key, expected) in cases {
            XCTAssertEqual(try extractor.extractDataRepresentedBy(String.self,
                                                                  propertyChain: "DATA.creativeImage.hero.\(key)",
                                                                  responseKey: nil, from: offer), .value(expected))
        }
    }

    private func alternatives(namespace: String, key: String) -> [(String, String)] {
        let value = "\(namespace).\(key)"
        return [
            ("\(value):sliceText[Chars,2]|\(value):unknown[]", "ab"),
            ("\(value):unknown[]|\(value):sliceText[Chars,3]|fallback", "abc"),
            ("\(namespace).missing:sliceText[Chars,2]|\(value):sliceText[Chars,3]|\(value):unknown[]", "abc"),
            ("\(value):unknown[]|fallback", "fallback")
        ]
    }

    private var catalogItem: CatalogItem {
        CatalogItem.mock(catalogItemId: "abcdef", images: nil)
    }

    private var offer: OfferModel {
        OfferModel(campaignId: nil,
                   creative: CreativeModel(referralCreativeId: "creative", instanceGuid: "instance",
                                           copy: ["copy": "abcdef"],
                                           images: ["hero": CreativeImage(light: "https://example.com/image.png",
                                                                          dark: "https://example.com/dark.png",
                                                                          alt: "Alternative text", title: "Image title")],
                                           links: ["policy": CreativeLink(url: "https://example.com/privacy",
                                                                          title: "Privacy policy")],
                                           responseOptionsMap: nil, jwtToken: ""),
                   catalogItems: nil, catalogItemGroup: nil, transactionData: nil)
    }
}
