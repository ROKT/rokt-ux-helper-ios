import XCTest
@testable import RoktUXHelper

final class DataReflectorTests: XCTestCase {
    var sut: DataReflector!

    override func setUp() {
        super.setUp()

        sut = DataReflector()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test_getReflectedValue_withValidKeys_returnsValue() {
        XCTAssertEqual(
            sut.getReflectedValue(data: fakeSuburbMirror, keys: ["house", "owner", "pet", "name"]) as? String,
            "Ginger"
        )
    }

    func test_getReflectedValue_withInvalidKeys_returnsNil() {
        XCTAssertNil(sut.getReflectedValue(data: fakeSuburbMirror, keys: ["nonexistent"]))
    }

    func test_getReflectedValue_withPartialKeys_returnsNonStringValue() {
        // With Any? return type, partial keys resolve to the intermediate object
        XCTAssertNotNil(sut.getReflectedValue(data: fakeSuburbMirror, keys: ["house", "owner"]))
    }

    func test_getReflectedValue_withHeterogeneousDictionary_returnsValue() {
        let productMirror = Mirror(reflecting: ProductDetails(copy: ["pricing.amount": 14.99]))

        XCTAssertEqual(
            sut.getReflectedValue(data: productMirror, keys: ["copy", "pricing", "amount"]) as? Double,
            14.99
        )
    }

    func test_getReflectedValue_dictOfStructs_resolvesLeafField() {
        // images is a [String: ReflectorTestImage] map. Resolving
        // images.<key>.<field> must drill through the struct value, since the
        // joined-key lookup ("catalogItemImage2.light") would otherwise miss.
        let catalogMirror = Mirror(reflecting: ReflectorTestCatalog(images: [
            "catalogItemImage0": ReflectorTestImage(light: "url0", dark: nil),
            "catalogItemImage2": ReflectorTestImage(light: "url2", dark: "dark2")
        ]))

        XCTAssertEqual(
            sut.getReflectedValue(data: catalogMirror, keys: ["images", "catalogItemImage2", "light"]) as? String,
            "url2"
        )
        XCTAssertEqual(
            sut.getReflectedValue(data: catalogMirror, keys: ["images", "catalogItemImage2", "dark"]) as? String,
            "dark2"
        )
    }

    func test_getReflectedValue_dictOfStructs_missingDictKey_returnsNil() {
        let catalogMirror = Mirror(reflecting: ReflectorTestCatalog(images: [
            "catalogItemImage0": ReflectorTestImage(light: "url0", dark: nil)
        ]))

        XCTAssertNil(
            sut.getReflectedValue(data: catalogMirror, keys: ["images", "catalogItemImage2", "light"])
        )
    }

    func test_getReflectedValue_dictOfStructs_missingLeafField_returnsNil() {
        // Optional<String> with .none should surface as nil after the leaf lookup.
        let catalogMirror = Mirror(reflecting: ReflectorTestCatalog(images: [
            "catalogItemImage2": ReflectorTestImage(light: nil, dark: nil)
        ]))

        let result = sut.getReflectedValue(data: catalogMirror, keys: ["images", "catalogItemImage2", "light"])
        // The reflector returns the raw Optional<String>.none here; callers
        // (CatalogDataExtractor.unwrapOptional) collapse that to nil.
        XCTAssertNil(result as? String)
    }
}

struct Pet {
    let name: String
}

struct Human {
    let pet: Pet
}

struct House {
    let owner: Human
}

struct Suburb {
    let house: House
}

struct ProductDetails {
    let copy: [String: Any]
}

struct ReflectorTestImage {
    let light: String?
    let dark: String?
}

struct ReflectorTestCatalog {
    let images: [String: ReflectorTestImage]
}

let fakePet = Pet(name: "Ginger")
let fakeHuman = Human(pet: fakePet)
let fakeHouse = House(owner: fakeHuman)
let fakeSuburb = Suburb(house: fakeHouse)
let fakeSuburbMirror = Mirror(reflecting: Suburb(house: fakeHouse))
