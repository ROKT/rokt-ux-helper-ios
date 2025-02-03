//
//  TestWhenViewModel.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
import SwiftUI
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15, *)
final class TestWhenViewModel: XCTestCase {
    
    func get_when_view_model(children: [LayoutSchemaViewModel]? = [],
                             predicates: [WhenPredicate]? = [],
                             transition: WhenTransition? = nil,
                             copy: [String: String] = [String: String](),
                             breakPoint: BreakPoint? = nil) -> WhenViewModel {
        return WhenViewModel(children: children,
                             predicates: predicates,
                             transition: transition,
                             slots: [get_slot_offer(copy: copy)],
                             globalBreakPoints: breakPoint,
                             layoutState: LayoutState())
    }
    
    func test_should_apply_progression_is_valid() {
        // Arrange
        let predicate = WhenPredicate.progression(
            ProgressionPredicate(condition: .is, value: "0"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_progression_is_invalid() {
        // Arrange
        let predicate = WhenPredicate.progression(
            ProgressionPredicate(condition: .is, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_progression_is_not_valid() {
        // Arrange
        let predicate = WhenPredicate.progression(
            ProgressionPredicate(condition: .isNot, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_progression_is_not_invalid() {
        // Arrange
        let predicate = WhenPredicate.progression(
            ProgressionPredicate(condition: .isNot, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(currentProgress: 1))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_progression_above_valid() {
        // Arrange
        let predicate = WhenPredicate.progression(
            ProgressionPredicate(condition: .isAbove, value: "0"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(currentProgress: 1))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_progression_above_invalid() {
        // Arrange
        let predicate = WhenPredicate.progression(
            ProgressionPredicate(condition: .isAbove, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_progression_below_valid() {
        // Arrange
        let predicate = WhenPredicate.progression(
            ProgressionPredicate(condition: .isBelow, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_progression_below_invalid() {
        // Arrange
        let predicate = WhenPredicate.progression(
            ProgressionPredicate(condition: .isBelow, value: "2"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(currentProgress: 3, totalOffers: 3))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    // MARK: position

    func test_should_apply_position_is_valid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "0"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 0))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_position_negative_is_valid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "-1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(totalOffers: 2, position: 1))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_position_is_invalid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 0))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_position_negative_is_invalid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "-1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(totalOffers: 2, position: 0))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_empty_position_false() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "0"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: nil))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_position_is_not_valid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .isNot, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 0))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_position_is_not_invalid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .isNot, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 1))
        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_position_above_valid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .isAbove, value: "0"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 1))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_position_above_invalid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .isAbove, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 1))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_position_below_valid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .isBelow, value: "1"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 0))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_position_below_invalid() {
        // Arrange
        let predicate = WhenPredicate.position(
            PositionPredicate(condition: .isBelow, value: "2"))
        let whenVM = get_when_view_model(predicates: [predicate])
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(totalOffers: 3, position: 3))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    // MARK: Breakpoint
    
    func test_should_apply_breakpoint_is_valid() {
        // Arrange
        let predicate = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .is, value: "mobile"))
        let whenVM = get_when_view_model(predicates: [predicate], breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 1))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_breakpoint_is_invalid() {
        // Arrange
        let predicate = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .is, value: "mobile"))
        let whenVM = get_when_view_model(predicates: [predicate], breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 501))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_breakpoint_is_not_valid() {
        // Arrange
        let predicate = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .isNot, value: "mobile"))
        let whenVM = get_when_view_model(predicates: [predicate], breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 501))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_breakpoint_is_not_invalid() {
        // Arrange
        let predicate = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .isNot, value: "mobile"))
        let whenVM = get_when_view_model(predicates: [predicate], breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 1))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_breakpoint_is_below_valid() {
        // Arrange
        let predicate = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .isBelow, value: "tablet"))
        let whenVM = get_when_view_model(predicates: [predicate], breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 200))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_breakpoint_is_below_invalid() {
        // Arrange
        let predicate = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .isBelow, value: "tablet"))
        let whenVM = get_when_view_model(predicates: [predicate], breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 600))

        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    func test_should_apply_breakpoint_is_above_valid() {
        // Arrange
        let predicate = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .isAbove, value: "tablet"))
        let whenVM = get_when_view_model(predicates: [predicate], breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 1000))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    func test_should_apply_breakpoint_is_above_invalid() {
        // Arrange
        let predicate = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .isAbove, value: "tablet"))
        let whenVM = get_when_view_model(predicates: [predicate], breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 400))

        // Assert
        XCTAssertFalse(shouldApply)
    }

    // MARK: - Dark Mode

    func test_shouldNOTApply_whenConditionEqualsIsAndValueEqualsTrue_andDarkModeIsFalse_shouldNotApply() {
        let predicate = WhenPredicate.darkMode(DarkModePredicate(condition: .is, value: true))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }

    func test_shouldApply_whenConditionEqualsIsAndValueEqualsFalse_andDarkModeIsFalse_shouldNotApply() {
        let predicate = WhenPredicate.darkMode(DarkModePredicate(condition: .is, value: false))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }

    func test_shouldApply_whenConditionEqualsIsNotAndValueEqualsTrue_andDarkModeIsFalse_shouldApply() {
        let predicate = WhenPredicate.darkMode(DarkModePredicate(condition: .isNot, value: true))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }

    func test_shouldNotApply_whenConditionEqualsIsNotAndValueEqualsFalse_andDarkModeIsFalse_shouldNotApply() {
        let predicate = WhenPredicate.darkMode(DarkModePredicate(condition: .isNot, value: false))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }
    
    // MARK: - StaticBoolean

    func test_shouldNotApply_whenConditionEqualsIsTrue_valueEqualsFalse() {
        let predicate = WhenPredicate.staticBoolean(StaticBooleanPredicate(condition: .isTrue, value: false))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }

    func test_shouldApply_whenConditionEqualsIsTrue_valueEqualsTrue() {
        let predicate = WhenPredicate.staticBoolean(StaticBooleanPredicate(condition: .isTrue, value: true))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }
    
    func test_shouldNotApply_whenConditionEqualsIsFalse_valueEqualsTrue() {
        let predicate = WhenPredicate.staticBoolean(StaticBooleanPredicate(condition: .isFalse, value: true))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }

    func test_shouldApply_whenConditionEqualsIsFalse_valueEqualsFalse() {
        let predicate = WhenPredicate.staticBoolean(StaticBooleanPredicate(condition: .isFalse, value: false))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }
    
    // MARK: - CreativeCopy

    func test_shouldApply_whenCreativeCopy_exists() {
        let predicate = WhenPredicate.creativeCopy(CreativeCopyPredicate(condition: .exists, value: "creative.title"))
        let whenVM = get_when_view_model(predicates: [predicate],
                                         copy: [ "creative.title": "Awesome offer"])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }   
    
    func test_shouldNotApply_whenCreativeCopy_notExists() {
        let predicate = WhenPredicate.creativeCopy(CreativeCopyPredicate(condition: .exists, value: "creative.title"))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }    
    
    func test_shouldNotApply_whenCreativeCopy_notExists_differentValue() {
        let predicate = WhenPredicate.creativeCopy(CreativeCopyPredicate(condition: .exists, value: "creative.title"))
        let whenVM = get_when_view_model(predicates: [predicate], copy: ["creative.copy": "Awesome offer"])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }       
    
    func test_shouldNotApply_whenCreativeCopy_notExists_emptyValue() {
        let predicate = WhenPredicate.creativeCopy(CreativeCopyPredicate(condition: .exists, value: "creative.title"))
        let whenVM = get_when_view_model(predicates: [predicate], copy: ["creative.title": ""])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }    
    
    func test_shouldNotApply_whenCreativeCopy_multiple() {
        let predicate1 = WhenPredicate.creativeCopy(CreativeCopyPredicate(condition: .exists, value: "creative.title"))
        let predicate2 = WhenPredicate.creativeCopy(CreativeCopyPredicate(condition: .exists, value: "creative.copy"))
        let whenVM = get_when_view_model(predicates: [predicate1, predicate2], copy: ["creative.title": "Awesome offer"])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }    
    
    func test_shouldApply_whenCreativeCopy_multiple() {
        let predicate1 = WhenPredicate.creativeCopy(CreativeCopyPredicate(condition: .exists, value: "creative.title"))
        let predicate2 = WhenPredicate.creativeCopy(CreativeCopyPredicate(condition: .exists, value: "creative.copy"))
        let whenVM = get_when_view_model(
            predicates: [predicate1, predicate2],
            copy: ["creative.title": "Awesome offer", "creative.copy": "For you"])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }
    
    // MARK: - StaticString

    func test_shouldApply_whenConditionEqualsIs_inputEqualsTest_valueEqualsTest() {
        let predicate = WhenPredicate.staticString(StaticStringPredicate(input: "test", condition: .is, value: "test"))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }

    func test_shouldNotApply_whenConditionEqualsIs_inputEqualsTest_valueEqualsNotTest() {
        let predicate = WhenPredicate.staticString(StaticStringPredicate(input: "test", condition: .is, value: "nottest"))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }
    
    func test_shouldApply_whenConditionEqualsIsNot_inputEqualsTest_valueEqualsNotTest() {
        let predicate = WhenPredicate.staticString(StaticStringPredicate(input: "test", condition: .isNot, value: "nottest"))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }

    func test_shouldNotApply_whenConditionEqualsIsNot_inputEqualsTest_valueEqualsTest() {
        let predicate = WhenPredicate.staticString(StaticStringPredicate(input: "test", condition: .isNot, value: "test"))
        let whenVM = get_when_view_model(predicates: [predicate])

        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }
    
    // MARK: - CustomState

    func test_shouldNotApply_customStateMapNil() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .is, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertFalse(shouldApply)
    }
    
    func test_shouldNotApply_whenConditionEqualsIsNot_customStateMapNil() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .isNot, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let shouldApply = whenVM.shouldApply(get_mock_uistate())

        XCTAssertTrue(shouldApply)
    }
    
    func test_shouldNotApply_customStateMapInvalidKey() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .is, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let customStateId = CustomStateIdentifiable(position: nil, key: "otherState")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 1)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertFalse(shouldApply)
    }
    
    func test_shouldApply_whenConditionEqualsIs_valueEqualsCustomState() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .is, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        let customStateId = CustomStateIdentifiable(position: nil, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 1)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertTrue(shouldApply)
    }
    
    func test_shouldNotApply_whenConditionEqualsIs_valueNotEqualsCustomState() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .is, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let customStateId = CustomStateIdentifiable(position: nil, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 0)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertFalse(shouldApply)
    }
    
    func test_shouldApply_whenConditionEqualsIsNot_valueNotEqualsCustomState() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .isNot, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let customStateId = CustomStateIdentifiable(position: nil, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 11)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertTrue(shouldApply)
    }
    
    func test_shouldNotApply_whenConditionEqualsIsNot_valueEqualsCustomState() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .isNot, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let customStateId = CustomStateIdentifiable(position: nil, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 1)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertFalse(shouldApply)
    }
    
    func test_shouldApply_whenConditionEqualsIsAbove_customStateAboveValue() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .isAbove, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let customStateId = CustomStateIdentifiable(position: nil, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 21)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertTrue(shouldApply)
    }
    
    func test_shouldNotApply_whenConditionEqualsIsAbove_customStateNotAboveValue() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .isAbove, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let customStateId = CustomStateIdentifiable(position: nil, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 1)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertFalse(shouldApply)
    }
    
    func test_shouldApply_whenConditionEqualsIsBelow_customStateBelowValue() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .isBelow, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let customStateId = CustomStateIdentifiable(position: nil, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 0)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertTrue(shouldApply)
    }
    
    func test_shouldNotApply_whenConditionEqualsIsBelow_customStateNotBelowValue() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .isAbove, value: 11))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        let customStateId = CustomStateIdentifiable(position: nil, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 11)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(customStateMap: customStateMap))

        XCTAssertFalse(shouldApply)
    }
    
    func test_shouldNotApply_whenConditionEqualsIs_valueEqualsCustomState_positionNotEquals() {
        let predicate = WhenPredicate.customState(CustomStatePredicate(
            key: "state", condition: .is, value: 1))
        let whenVM = get_when_view_model(predicates: [predicate])
        
        // Setup customStateMap with ["state": 1] on position 0
        let customStateId = CustomStateIdentifiable(position: 0, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 1)])
        // Should not apply as uiState on position 1
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 1,
                                                              customStateMap: customStateMap))

        XCTAssertFalse(shouldApply)
    }

    // MARK: Combination
    
    // Test multiple predicates together
    func test_should_apply_breakpoint_position_progression_is_valid() {
        // Arrange
        let predicate1 = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .is, value: "mobile"))
        let predicate2 = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "-1"))
        let predicate3 = WhenPredicate.progression(
            ProgressionPredicate(condition: .is, value: "0"))
        let predicate4 = WhenPredicate.darkMode(
            DarkModePredicate(condition: .is, value: true))

        let whenVM = get_when_view_model(
            predicates: [predicate1, predicate2, predicate3, predicate4],
            breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 0, width: 1, isDarkMode: true))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    // Test multiple predicates together
    func test_should_apply_breakpoint_position_progression_is_invalid() {
        // Arrange
        let predicate1 = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .is, value: "mobile"))
        // This one should fail
        let predicate2 = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "-2"))
        let predicate3 = WhenPredicate.progression(
            ProgressionPredicate(condition: .is, value: "0"))
        let predicate4 = WhenPredicate.darkMode(
            DarkModePredicate(condition: .isNot, value: true))

        let whenVM = get_when_view_model(
            predicates: [predicate1, predicate2, predicate3, predicate4],
            breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 0, width: 1))
        
        // Assert
        XCTAssertFalse(shouldApply)
    }
    
    // Test breakpoint, position, progression, darkMode and customState together
    func test_shouldApply_breakpoint_position_progression_darkMode_customState() {
        // Arrange
        let predicate1 = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .is, value: "mobile"))
        let predicate2 = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "-1"))
        let predicate3 = WhenPredicate.progression(
            ProgressionPredicate(condition: .is, value: "0"))
        let predicate4 = WhenPredicate.darkMode(
            DarkModePredicate(condition: .is, value: true))
        let predicate5 = WhenPredicate.customState(
            CustomStatePredicate(key: "state", condition: .is, value: 21))

        let whenVM = get_when_view_model(predicates: [predicate1, predicate2, predicate3, predicate4, predicate5],
                                         breakPoint: get_shared_data_with_breakpoints())
        // Act
        let customStateId = CustomStateIdentifiable(position: 0, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 21)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 0,
                                                              width: 1,
                                                              isDarkMode: true,
                                                              customStateMap: customStateMap))

        XCTAssertTrue(shouldApply)
    }
    
    func test_shouldNotApply_breakpoint_position_progression_darkMode_customStateNotEqual() {
        let predicate1 = WhenPredicate.breakpoint(
            BreakpointPredicate(condition: .is, value: "mobile"))
        let predicate2 = WhenPredicate.position(
            PositionPredicate(condition: .is, value: "-1"))
        let predicate3 = WhenPredicate.progression(
            ProgressionPredicate(condition: .is, value: "0"))
        let predicate4 = WhenPredicate.darkMode(
            DarkModePredicate(condition: .is, value: true))
        let predicate5 = WhenPredicate.customState(
            CustomStatePredicate(key: "state", condition: .is, value: 21))
        
        let whenVM = get_when_view_model(predicates: [predicate1, predicate2, predicate3, predicate4, predicate5],
                                         breakPoint: get_shared_data_with_breakpoints())
        // Act
        let customStateId = CustomStateIdentifiable(position: 0, key: "state")
        let customStateMap = RoktUXCustomStateMap(uniqueKeysWithValues: [(key: customStateId,
                                                                    value: 2)])
        let shouldApply = whenVM.shouldApply(get_mock_uistate(position: 0,
                                                              width: 1,
                                                              isDarkMode: true,
                                                              customStateMap: customStateMap))

        XCTAssertFalse(shouldApply)
    }
    
    // MARK: Empty

    // Test empty
    func test_shouldApply_whenPredicatesEmpty() {
        // Arrange
        let whenVM = get_when_view_model(breakPoint: get_shared_data_with_breakpoints())
        // Act
        let shouldApply = whenVM.shouldApply(get_mock_uistate(width: 1, isDarkMode: true))

        // Assert
        XCTAssertTrue(shouldApply)
    }
    
    // MARK: - Transitions

    func test_shouldExtractDuration_whenTransition_fadeInOut() {
        // Arrange
        let whenTransition = WhenTransition(inTransition: [.fadeIn(FadeInTransitionSettings(duration: 200))],
                                            outTransition: [.fadeOut(FadeOutTransitionSettings(duration: 300))])
        let whenVM = get_when_view_model(transition: whenTransition)
        // Act
        let fadeInDuration = whenVM.fadeInDuration
        let fadeOutDuration = whenVM.fadeOutDuration

        // Assert
        XCTAssertEqual(fadeInDuration, 0.2)
        XCTAssertEqual(fadeOutDuration, 0.3)
    }
    
    private func get_slot_offer(copy: [String: String]) -> SlotOfferModel {
        return SlotOfferModel(offer: OfferModel(
            campaignId: "Campaign1",
            creative: CreativeModel(
                referralCreativeId: "referralCreativeId1",
                instanceGuid: "instanceGuid",
                copy: copy,
                images: nil,
                links: nil,
                responseOptionsMap: nil,
                jwtToken: "jwtToken1")))
    }
    
    func get_shared_data_with_breakpoints() -> BreakPoint {
        return ["mobile": 1, "tablet": 500, "desktop": 1000] as BreakPoint
    }
}
