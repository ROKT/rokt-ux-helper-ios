//
//  TestLayoutTransformer.swift
//  RoktUXHelperTests
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import XCTest
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15, *)
final class TestLayoutTransformer: XCTestCase {
    
    func test_creative_response_includes_positive_response_option() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.positive() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = ResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalGatedResponse,
            shortLabel: "Yes please",
            longLabel: "Yes please",
            shortSuccessLabel: "",
            isPositive: true,
            url: "",
            responseJWTToken: "response-jwt")
        let slot = get_slot(responseOptionList: ResponseOptionList(positive: responseOption,
                                                                   negative: nil))
        
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))
        
        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponseUIModel(
            responseKey: model.responseKey,
            openLinks: nil,
            styles: model.styles,
            children: layoutTransformer.transformChildren(model.children, context: .inner(.positive(slot.offer!))),
            offer: slot.offer!
        )
        
        // Assert
        XCTAssertEqual(transformedCreativeResponse.responseOptions, responseOption)
    }
    
    func test_creative_response_includes_negative_response_option() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.negative() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = ResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token"
        )
        let slot = get_slot(responseOptionList: ResponseOptionList(positive: nil,
                                                                   negative: responseOption))
        
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))
        
        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponseUIModel(
            responseKey: model.responseKey,
            openLinks: nil,
            styles: model.styles,
            children: layoutTransformer.transformChildren(model.children, context: .inner(.negative(slot.offer!))),
            offer: slot.offer!
        )
        
        // Assert
        XCTAssertEqual(transformedCreativeResponse.responseOptions, responseOption)
    }
    
    func test_creative_response_includes_negative_response_option_with_breakpoint() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.negative() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = ResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token"
        )
        let slot = get_slot(responseOptionList: ResponseOptionList(positive: nil,
                                                                   negative: responseOption))
        
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))
        
        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponseUIModel(
            responseKey: model.responseKey,
            openLinks: nil,
            styles: model.styles,
            children: layoutTransformer.transformChildren(model.children, context: .inner(.negative(slot.offer!))),
            offer: slot.offer!
        )
        
        // Assert
        
        // first breakpoint default
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].spacing?.margin, "10 0 0 0")
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].container?.justifyContent, .center)
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].border?.borderRadius, 0)
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].border?.borderWidth, "2")
        // first breakpoint pressed
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].spacing?.margin, "10 0 0 0")
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].container?.justifyContent, .center)
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].border?.borderRadius, 0)
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].border?.borderWidth, "2")
        // second breakpoint default
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].spacing?.margin, "10 0 0 0")
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].dimension?.height, .fit(.fitHeight))
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].container?.justifyContent, .center)
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].border?.borderRadius, 0)
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].border?.borderWidth, "2")
        // second breakpoint pressed
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].spacing?.margin, "10 0 0 0")
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].dimension?.height, .fit(.fitHeight))
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].container?.justifyContent, .center)
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].border?.borderRadius, 10)
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].border?.borderWidth, "4")
        
    }
    
    func test_creative_response_negative_not_presented() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.negative() else {
            XCTFail("Could not load the json")
            return
        }
        let slot = get_slot(responseOptionList: nil)
        
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))
        
        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponse(
            model: model,
            context: .inner(.generic(slot.offer!))
        )
        
        // Assert
        XCTAssertEqual(transformedCreativeResponse, .empty)
    }
    
    func test_creative_response_neutral_not_presented() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.neutral() else {
            XCTFail("Could not load the json")
            return
        }
        let positiveResponseOption = ResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalGatedResponse,
            shortLabel: "Yes please",
            longLabel: "Yes please",
            shortSuccessLabel: "",
            isPositive: true,
            url: "",
            responseJWTToken: "response-token"
        )
        let negativeResponseOption = ResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token"
        )
        let slot = get_slot(responseOptionList: ResponseOptionList(positive: positiveResponseOption,
                                                                   negative: negativeResponseOption))
        
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))
        
        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponse(
            model: model,
            context: .inner(.generic(slot.offer!))
        )
        
        // Assert
        XCTAssertEqual(transformedCreativeResponse, .empty)
    }
    
    // MARK: - ProgressIndicatorTests
    func test_progressIndicator_withSingleDataExpansion_parsesUnexpandedData() throws {
        let model = ModelTestData.ProgressIndicatorData.progressIndicator()
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: []))
        
        let layoutSchemaUIModel = try layoutTransformer.getProgressIndicatorUIModel(model, context: .inner(.generic(nil)))
        XCTAssertEqual(layoutSchemaUIModel.indicator, "%^STATE.IndicatorPosition^%")
    }
    
    func test_progressIndicator_withValidChainOfDataExpansion_parsesUnexpandedData() throws {
        let model = ModelTestData.ProgressIndicatorData.chainOfvaluesDataExpansion()
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: []))
        
        let layoutSchemaUIModel = try layoutTransformer.getProgressIndicatorUIModel(model, context: .inner(.generic(nil)))
        XCTAssertEqual(layoutSchemaUIModel.indicator, "%^STATE.InitialWrongValue | STATE.IndicatorPosition^%")
    }
    
//    func test_progressIndicator_withInvalidDataExpansion_shouldReturnEmpty() throws {
//        let model = ModelTestData.ProgressIndicatorData.invalidDataExpansion()
//        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: []))
//        
//        let layoutSchemaUIModel = try layoutTransformer.getProgressIndicatorUIModel(model, context: .inner(.generic(nil)))
//
//        XCTAssertEqual(uiModel, .empty)
//    }
    
    //MARK: Onebyone
    func test_transform_onebyone() throws {
        // Arrange
        guard let model = ModelTestData.OneByOneData.oneByOne(),
              let response = ModelTestData.CreativeResponseData.negative() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = ResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token"
        )
        let slot = get_slot(responseOptionList: ResponseOptionList(positive: nil,
                                                                   negative: responseOption),
                            layoutVariant: response)
        
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: .oneByOneDistribution(model), slots: [slot]))
        
        // Act
        let transformedOneByOne = try layoutTransformer.getOneByOne(oneByOneModel: model, context: .outer([slot.offer]))
        
        // Assert
        
        // oneByOne loaded with children from slot
        XCTAssertEqual(transformedOneByOne.children?.count, 1)
        // loaded styles in the breakpoint
        XCTAssertEqual(transformedOneByOne.defaultStyle?[0].background?.backgroundColor?.light, "#000000")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[0].spacing?.padding, "3 4 5 6")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[0].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(transformedOneByOne.defaultStyle?[0].container?.justifyContent, .center)
        // second breakpoint
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].background?.backgroundColor?.light, "#000000")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].spacing?.padding, "5 5 5 5")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].spacing?.margin, "10")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].container?.justifyContent, .center)
    }
    
    //MARK: Column
    func test_column_breakpoint() throws {
        // Arrange
        let model = ModelTestData.ColumnData.columnWithBasicText()
        
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: []))
        
        // Act
        let transformedColumn = try layoutTransformer.getColumn(model.styles, children: nil)
        
        // Assert
        XCTAssertEqual(transformedColumn.defaultStyle?[0].background?.backgroundColor?.light, "#F5C1C4")
        XCTAssertEqual(transformedColumn.defaultStyle?[1].background?.backgroundColor?.light, "#999999")
    }
    
    //MARK: ToggleButtonStateTrigger
    func test_toggleButton_transformed() throws {
        // Arrange
        let model = ModelTestData.ToggleButtonData.basicToggleButton()
        
        let layoutTransformer = LayoutTransformer(layoutPlugin: get_layout_plugin(layout: nil, slots: []))
        
        // Act
        let transformedToggleButton = try layoutTransformer.getToggleButton(
            customStateKey: model.customStateKey,
            styles: model.styles,
            children: nil)
        
        // Assert
        XCTAssertEqual(transformedToggleButton.customStateKey, "stateKey")
        XCTAssertEqual(transformedToggleButton.defaultStyle?[0].background?.backgroundColor?.light, "#FFFFFF")
        XCTAssertEqual(transformedToggleButton.pressedStyle?[0].background?.backgroundColor?.light, "#F5C1C4")
        XCTAssertEqual(transformedToggleButton.defaultStyle?[1].background?.backgroundColor?.light, "#F2A7AB")
    }
    
    //MARK: mock objects
    func get_layout_plugin(layout: LayoutSchemaModel?, slots: [SlotModel]) -> LayoutPlugin {
        return get_mock_layout_plugin(layout: layout, slots: slots)
    }
    
    func get_slot(responseOptionList: ResponseOptionList?,
                  layoutVariant: CreativeResponseModel<LayoutSchemaModel, WhenPredicate>? = nil) -> SlotModel {
        SlotModel(
            instanceGuid: "",
            offer: .mock(responseOptionList: responseOptionList, token: "creative-token"),
            layoutVariant: layoutVariant == nil ? nil : LayoutVariantModel(
                layoutVariantSchema: .creativeResponse(layoutVariant!), moduleName: ""
            ),
            jwtToken: "slot-token"
        )
    }
}
