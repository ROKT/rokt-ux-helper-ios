//
//  DataReflectorTests.swift
//  RoktUXHelper
//
//  Copyright 2020 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

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
        XCTAssertEqual(sut.getReflectedValue(data: fakeSuburbMirror, keys: ["house", "owner", "pet", "name"]), "Ginger")
    }

    func test_getReflectedValue_withInvalidKeys_returnsNil() {
        XCTAssertNil(sut.getReflectedValue(data: fakeSuburbMirror, keys: ["house", "owner"]))
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

let fakePet = Pet(name: "Ginger")
let fakeHuman = Human(pet: fakePet)
let fakeHouse = House(owner: fakeHuman)
let fakeSuburb = Suburb(house: fakeHouse)
let fakeSuburbMirror = Mirror(reflecting: Suburb(house: fakeHouse))
