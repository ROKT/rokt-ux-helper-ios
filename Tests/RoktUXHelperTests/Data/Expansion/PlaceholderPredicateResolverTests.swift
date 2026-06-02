import XCTest
@testable import RoktUXHelper

@available(iOS 13, *)
final class PlaceholderPredicateResolverTests: XCTestCase {
    var sut: PlaceholderPredicateResolver!

    override func setUp() {
        super.setUp()
        sut = PlaceholderPredicateResolver()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_resolveDecimal_catalogItemPrice() {
        let catalogItem = CatalogItem.mock(catalogItemId: "item1", images: nil)
        let context = PlaceholderResolutionContext(offers: [],
                                                   currentOfferIndex: 0,
                                                   activeCatalogItem: catalogItem)

        let resolved = sut.resolveDecimal(placeholder: "%^DATA.catalogItem.price^%", context: context)

        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved, Decimal(14.99))
    }

    func test_resolveString_catalogItemPrice() {
        let catalogItem = CatalogItem.mock(catalogItemId: "item1", images: nil)
        let context = PlaceholderResolutionContext(offers: [],
                                                   currentOfferIndex: 0,
                                                   activeCatalogItem: catalogItem)

        let resolved = sut.resolveString(placeholder: "%^DATA.catalogItem.price^%", context: context)

        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved, "14.99")
    }

    func test_resolveString_catalogItemImagePresent_returnsLeafLightURL() {
        // Verifies the DataReflector dict-of-struct recursion lands a real URL
        // when the placeholder targets a nested field on a struct dict value.
        let images: [String: CreativeImage] = [
            "catalogItemImage0": CreativeImage(light: "url0", dark: nil, alt: nil, title: nil),
            "catalogItemImage2": CreativeImage(light: "url2", dark: nil, alt: nil, title: nil)
        ]
        let catalogItem = CatalogItem.mock(catalogItemId: "item1", images: images)
        let context = PlaceholderResolutionContext(offers: [],
                                                   currentOfferIndex: 0,
                                                   activeCatalogItem: catalogItem)

        let resolved = sut.resolveString(
            placeholder: "%^DATA.catalogItem.images.catalogItemImage2.light^%",
            context: context
        )

        XCTAssertEqual(resolved, "url2")
    }

    func test_resolveString_catalogItemImageAbsent_returnsNil() {
        // Verifies that a missing dict key still surfaces as nil rather than
        // resolving to the wrong image (the original bug was the layout
        // falling back to a sibling image via a |-chain).
        let images: [String: CreativeImage] = [
            "catalogItemImage0": CreativeImage(light: "url0", dark: nil, alt: nil, title: nil)
        ]
        let catalogItem = CatalogItem.mock(catalogItemId: "item1", images: images)
        let context = PlaceholderResolutionContext(offers: [],
                                                   currentOfferIndex: 0,
                                                   activeCatalogItem: catalogItem)

        let resolved = sut.resolveString(
            placeholder: "%^DATA.catalogItem.images.catalogItemImage2.light^%",
            context: context
        )

        XCTAssertNil(resolved)
    }

    func test_resolveString_catalogItemImagePathToStruct_returnsEmptyString() {
        // When a placeholder stops at the struct level instead of a leaf field,
        // the extractor's coerce(String.self) fallback now returns "" instead
        // of crashing on `as! U`. Empty string makes Placeholder TextValue
        // `exists` evaluate to false (PredicateHandling treats empty as absent).
        let images: [String: CreativeImage] = [
            "catalogItemImage2": CreativeImage(light: "url2", dark: nil, alt: nil, title: nil)
        ]
        let catalogItem = CatalogItem.mock(catalogItemId: "item1", images: images)
        let context = PlaceholderResolutionContext(offers: [],
                                                   currentOfferIndex: 0,
                                                   activeCatalogItem: catalogItem)

        let resolved = sut.resolveString(
            placeholder: "%^DATA.catalogItem.images.catalogItemImage2^%",
            context: context
        )

        XCTAssertEqual(resolved, "")
    }
}
