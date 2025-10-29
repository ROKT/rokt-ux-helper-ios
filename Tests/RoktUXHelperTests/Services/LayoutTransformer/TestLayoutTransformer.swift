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

import DcuiSchema
import XCTest

@testable import RoktUXHelper

@available(iOS 15, *)
final class TestLayoutTransformer: XCTestCase {

    func test_creative_response_includes_positive_response_option() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.positive() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = RoktUXResponseOption(
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
        let slot = get_slot(
            responseOptionList: ResponseOptionList(
                positive: responseOption,
                negative: nil))

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))

        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponseUIModel(
            responseKey: model.responseKey,
            openLinks: nil,
            styles: model.styles,
            children: layoutTransformer.transformChildren(
                model.children, context: .inner(.positive(slot.offer!))),
            offer: slot.offer!)

        // Assert
        XCTAssertEqual(transformedCreativeResponse.responseOptions, responseOption)
    }

    func test_catalog_dropdown_uses_disabled_template_for_out_of_stock_items() throws {
        // Arrange
        let enabledItem = CatalogItem.mock(catalogItemId: "enabled", inventoryStatus: "InStock")
        let disabledItem = CatalogItem.mock(
            catalogItemId: "disabled", inventoryStatus: "OutOfStock")
        let offer = OfferModel.mock(catalogItems: [enabledItem, disabledItem])
        let slot = SlotModel(
            instanceGuid: nil,
            offer: offer,
            layoutVariant: nil,
            jwtToken: "slot-token")
        let layoutState = LayoutState()
        layoutState.items[LayoutState.fullOfferKey] = offer

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]),
            layoutState: layoutState)

        let openTemplate = LayoutSchemaModel.basicText(
            BasicTextModel<WhenPredicate>(styles: nil, value: "enabled"))
        let openDisabledTemplate = LayoutSchemaModel.basicText(
            BasicTextModel<WhenPredicate>(styles: nil, value: "disabled"))
        let closedTemplate = LayoutSchemaModel.basicText(
            BasicTextModel<WhenPredicate>(styles: nil, value: "closed"))
        let dropdownModel: CatalogDropdownModel<LayoutSchemaModel, WhenPredicate> =
            CatalogDropdownModel(
                openTemplate: openTemplate,
                openDisabledTemplate: openDisabledTemplate,
                closedTemplate: closedTemplate,
                closedDefaultTemplate: closedTemplate,
                requiredSelectionErrorTemplate: nil,
                validatorFieldConfig: nil,
                a11yLabel: nil,
                styles: nil)

        // Act
        let dropdownViewModel = try layoutTransformer.getCatalogDropdownModel(
            model: dropdownModel,
            context: .inner(.addToCart(enabledItem)))

        // Assert
        XCTAssertEqual(dropdownViewModel.openDropdownChildren.count, 2)

        if case .basicText(let firstChild) = dropdownViewModel.openDropdownChildren[0] {
            XCTAssertEqual(firstChild.boundValue, "enabled")
        } else {
            XCTFail("Expected first dropdown child to be basic text")
        }

        if case .basicText(let secondChild) = dropdownViewModel.openDropdownChildren[1] {
            XCTAssertEqual(secondChild.boundValue, "disabled")
        } else {
            XCTFail("Expected second dropdown child to be basic text")
        }
    }

    func test_creative_response_includes_positive_response_option_with_external_action() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.positive() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = RoktUXResponseOption(
            id: "",
            action: .external,
            instanceGuid: "",
            signalType: .signalGatedResponse,
            shortLabel: "Yes please",
            longLabel: "Yes please",
            shortSuccessLabel: "",
            isPositive: true,
            url: "",
            responseJWTToken: "response-jwt")
        let slot = get_slot(
            responseOptionList: ResponseOptionList(
                positive: responseOption,
                negative: nil))

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))

        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponseUIModel(
            responseKey: model.responseKey,
            openLinks: nil,
            styles: model.styles,
            children: layoutTransformer.transformChildren(
                model.children, context: .inner(.positive(slot.offer!))),
            offer: slot.offer!)

        // Assert
        XCTAssertEqual(transformedCreativeResponse.responseOptions, responseOption)
    }

    func test_creative_response_includes_negative_response_option() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.negative() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = RoktUXResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token")
        let slot = get_slot(
            responseOptionList: ResponseOptionList(
                positive: nil,
                negative: responseOption))

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))

        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponseUIModel(
            responseKey: model.responseKey,
            openLinks: nil,
            styles: model.styles,
            children: layoutTransformer.transformChildren(
                model.children, context: .inner(.negative(slot.offer!))),
            offer: slot.offer!)

        // Assert
        XCTAssertEqual(transformedCreativeResponse.responseOptions, responseOption)
    }

    func test_creative_response_includes_negative_response_option_with_external_action() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.negative() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = RoktUXResponseOption(
            id: "",
            action: .external,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token")
        let slot = get_slot(
            responseOptionList: ResponseOptionList(
                positive: nil,
                negative: responseOption))

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))

        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponseUIModel(
            responseKey: model.responseKey,
            openLinks: nil,
            styles: model.styles,
            children: layoutTransformer.transformChildren(
                model.children, context: .inner(.negative(slot.offer!))),
            offer: slot.offer!)

        // Assert
        XCTAssertEqual(transformedCreativeResponse.responseOptions, responseOption)
    }

    func test_creative_response_includes_negative_response_option_with_breakpoint() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.negative() else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = RoktUXResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token")
        let slot = get_slot(
            responseOptionList: ResponseOptionList(
                positive: nil,
                negative: responseOption))

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))

        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponseUIModel(
            responseKey: model.responseKey,
            openLinks: nil,
            styles: model.styles,
            children: layoutTransformer.transformChildren(
                model.children, context: .inner(.negative(slot.offer!))),
            offer: slot.offer!)

        // Assert

        // first breakpoint default
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].spacing?.margin, "10 0 0 0")
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(
            transformedCreativeResponse.defaultStyle?[0].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(
            transformedCreativeResponse.defaultStyle?[0].container?.justifyContent, .center)
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].border?.borderRadius, 0)
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[0].border?.borderWidth, "2")
        // first breakpoint pressed
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].spacing?.margin, "10 0 0 0")
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(
            transformedCreativeResponse.pressedStyle?[0].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(
            transformedCreativeResponse.pressedStyle?[0].container?.justifyContent, .center)
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].border?.borderRadius, 0)
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[0].border?.borderWidth, "2")
        // second breakpoint default
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].spacing?.margin, "10 0 0 0")
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(
            transformedCreativeResponse.defaultStyle?[1].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(
            transformedCreativeResponse.defaultStyle?[1].dimension?.height, .fit(.fitHeight))
        XCTAssertEqual(
            transformedCreativeResponse.defaultStyle?[1].container?.justifyContent, .center)
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].border?.borderRadius, 0)
        XCTAssertEqual(transformedCreativeResponse.defaultStyle?[1].border?.borderWidth, "2")
        // second breakpoint pressed
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].spacing?.margin, "10 0 0 0")
        XCTAssertEqual(transformedCreativeResponse.pressedStyle?[1].spacing?.padding, "10 10 10 10")
        XCTAssertEqual(
            transformedCreativeResponse.pressedStyle?[1].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(
            transformedCreativeResponse.pressedStyle?[1].dimension?.height, .fit(.fitHeight))
        XCTAssertEqual(
            transformedCreativeResponse.pressedStyle?[1].container?.justifyContent, .center)
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

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))

        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponse(
            model: model,
            context: .inner(.generic(slot.offer!)))

        // Assert
        XCTAssertEqual(transformedCreativeResponse, .empty)
    }

    func test_creative_response_neutral_not_presented() throws {
        // Arrange
        guard let model = ModelTestData.CreativeResponseData.neutral() else {
            XCTFail("Could not load the json")
            return
        }
        let positiveResponseOption = RoktUXResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalGatedResponse,
            shortLabel: "Yes please",
            longLabel: "Yes please",
            shortSuccessLabel: "",
            isPositive: true,
            url: "",
            responseJWTToken: "response-token")
        let negativeResponseOption = RoktUXResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token")
        let slot = get_slot(
            responseOptionList: ResponseOptionList(
                positive: positiveResponseOption,
                negative: negativeResponseOption))

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: [slot]))

        // Act
        let transformedCreativeResponse = try layoutTransformer.getCreativeResponse(
            model: model,
            context: .inner(.generic(slot.offer!)))

        // Assert
        XCTAssertEqual(transformedCreativeResponse, .empty)
    }

    // MARK: - ProgressIndicatorTests

    func test_progressIndicator_withSingleDataExpansion_parsesUnexpandedData() throws {
        let model = ModelTestData.ProgressIndicatorData.progressIndicator()
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        let layoutSchemaUIModel = try layoutTransformer.getProgressIndicatorUIModel(
            model, context: .inner(.generic(nil)))
        XCTAssertEqual(layoutSchemaUIModel.indicator, "%^STATE.IndicatorPosition^%")
        guard case .state(let stateLabel) = layoutSchemaUIModel.dataBinding else {
            XCTFail("Failed to get indicator state")
            return
        }
        XCTAssertEqual(stateLabel, "IndicatorPosition")
    }

    func test_progressIndicator_outerLayer_withSingleDataExpansion_parsesUnexpandedData() throws {
        let model = ModelTestData.ProgressIndicatorData.progressIndicator()
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        let layoutSchemaUIModel = try layoutTransformer.getProgressIndicatorUIModel(
            model, context: .outer([]))
        XCTAssertEqual(layoutSchemaUIModel.indicator, "%^STATE.IndicatorPosition^%")
        guard case .state(let stateLabel) = layoutSchemaUIModel.dataBinding else {
            XCTFail("Failed to get indicator state")
            return
        }
        XCTAssertEqual(stateLabel, "IndicatorPosition")
    }

    func test_progressIndicator_withValidChainOfDataExpansion_parsesUnexpandedData() throws {
        let model = ModelTestData.ProgressIndicatorData.chainOfvaluesDataExpansion()
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        let layoutSchemaUIModel = try layoutTransformer.getProgressIndicatorUIModel(
            model, context: .inner(.generic(nil)))
        XCTAssertEqual(
            layoutSchemaUIModel.indicator, "%^STATE.InitialWrongValue | STATE.IndicatorPosition^%")
    }

    func test_progressIndicator_withInvalidDataExpansion_shouldReturnEmpty() throws {
        let model = ModelTestData.ProgressIndicatorData.invalidDataExpansion()
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        let layoutSchemaUIModel = try layoutTransformer.getProgressIndicatorUIModel(
            model, context: .inner(.generic(nil)))

        XCTAssertEqual(layoutSchemaUIModel.indicator, "%^STATE.SomeValueThatDoesNotWork^%")
    }

    //MARK: Onebyone

    func test_transform_onebyone() throws {
        // Arrange
        guard let model = ModelTestData.OneByOneData.oneByOne(),
            let response = ModelTestData.CreativeResponseData.negative()
        else {
            XCTFail("Could not load the json")
            return
        }
        let responseOption = RoktUXResponseOption(
            id: "",
            action: .url,
            instanceGuid: "",
            signalType: .signalResponse,
            shortLabel: "No Thanks",
            longLabel: "No Thanks",
            shortSuccessLabel: "",
            isPositive: false,
            url: "",
            responseJWTToken: "response-token")
        let slot = get_slot(
            responseOptionList: ResponseOptionList(
                positive: nil,
                negative: responseOption),
            layoutVariant: response)

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(
                layout: .oneByOneDistribution(model),
                slots: [slot]))

        // Act
        let transformedOneByOne = try layoutTransformer.getOneByOne(
            oneByOneModel: model, context: .outer([slot.offer]))

        // Assert

        // oneByOne loaded with children from slot
        XCTAssertEqual(transformedOneByOne.children?.count, 1)
        // loaded styles in the breakpoint
        XCTAssertEqual(
            transformedOneByOne.defaultStyle?[0].background?.backgroundColor?.light, "#000000")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[0].spacing?.padding, "3 4 5 6")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[0].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(transformedOneByOne.defaultStyle?[0].container?.justifyContent, .center)
        // second breakpoint
        XCTAssertEqual(
            transformedOneByOne.defaultStyle?[1].background?.backgroundColor?.light, "#000000")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].spacing?.padding, "5 5 5 5")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].spacing?.margin, "10")
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].dimension?.width, .fit(.fitWidth))
        XCTAssertEqual(transformedOneByOne.defaultStyle?[1].container?.justifyContent, .center)
    }

    //MARK: Column

    func test_column_breakpoint() throws {
        // Arrange
        let model = ModelTestData.ColumnData.columnWithBasicText()

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let transformedColumn = try layoutTransformer.getColumn(model.styles, children: nil)

        // Assert
        XCTAssertEqual(
            transformedColumn.defaultStyle?[0].background?.backgroundColor?.light, "#F5C1C4")
        XCTAssertEqual(
            transformedColumn.defaultStyle?[1].background?.backgroundColor?.light, "#999999")
    }

    //MARK: ToggleButtonStateTrigger

    func test_toggleButton_transformed() throws {
        // Arrange
        let model = ModelTestData.ToggleButtonData.basicToggleButton()

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let transformedToggleButton = try layoutTransformer.getToggleButton(
            customStateKey: model.customStateKey,
            styles: model.styles,
            children: nil)

        // Assert
        XCTAssertEqual(transformedToggleButton.customStateKey, "stateKey")
        XCTAssertEqual(
            transformedToggleButton.defaultStyle?[0].background?.backgroundColor?.light, "#FFFFFF")
        XCTAssertEqual(
            transformedToggleButton.pressedStyle?[0].background?.backgroundColor?.light, "#F5C1C4")
        XCTAssertEqual(
            transformedToggleButton.defaultStyle?[1].background?.backgroundColor?.light, "#F2A7AB")
    }

    func test_expand_withValidBNF_updatesNestedValues() throws {
        let bnfPageModel = ModelTestData.PageModelData.withBNF()

        let layoutTransformer = LayoutTransformer(
            layoutPlugin: (bnfPageModel.layoutPlugins?.first!)!)

        let transformedUIModel = try layoutTransformer.transform()

        guard case .overlay(let outerVM) = transformedUIModel else {
            XCTFail("Could not get outer layout")
            return
        }

        guard case .oneByOne(let oneByOneVM) = outerVM.children?[1] else {
            XCTFail("Could not get outer layout")
            return
        }

        guard case .column(let colVM) = oneByOneVM.children?.first else {
            XCTFail("Could not get outer layout")
            return
        }

        if case .basicText(let textModel) = colVM.children?[0] {
            XCTAssertEqual(textModel.boundValue, "my_t_and_cs_link ")
        } else {
            XCTFail("Could not parse BNF layouts test data")
        }

        // chain of offer descriptions
        if case .richText(let textModel) = colVM.children?[1] {
            XCTAssertEqual(
                textModel.boundValue, "My Offer TitleOffer description goes heremy_t_and_cs_link")
        } else {
            XCTFail("Could not parse BNF layouts test data")
        }
    }

    // MARK: - GetDataImage

    func test_getDataImage_withSingleKey_returnsImage() throws {
        // Arrange
        let image = CreativeImage(
            light: "https://rokt.com/image.png", dark: nil, alt: "alt", title: nil)
        let offer = get_offer_with_images(["creativeImage": image])
        let model = DataImageModel<WhenPredicate>(styles: nil, imageKey: "creativeImage")
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageViewModel = try layoutTransformer.getDataImage(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertEqual(dataImageViewModel.image, image)
    }

    func test_getDataImage_withSingleKey_and_addToCart_context_returnsImage() throws {
        // Arrange
        let image = CreativeImage(
            light: "https://rokt.com/image.png", dark: nil, alt: "alt", title: nil)
        let catalogItem = get_catalog_item(image: image)
        let model = DataImageModel<WhenPredicate>(styles: nil, imageKey: "creativeImage")
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageViewModel = try layoutTransformer.getDataImage(
            model, context: .inner(.addToCart(catalogItem)))

        // Assert
        XCTAssertEqual(dataImageViewModel.image, image)
    }

    func test_getDataImage_withMultipleKeys_firstKeyValid_returnsImage() throws {
        // Arrange
        let image1 = CreativeImage(
            light: "https://rokt.com/image1.png", dark: nil, alt: "alt1", title: nil)
        let image2 = CreativeImage(
            light: "https://rokt.com/image2.png", dark: nil, alt: "alt2", title: nil)
        let offer = get_offer_with_images(["image1": image1, "image2": image2])
        let model = DataImageModel<WhenPredicate>(styles: nil, imageKey: "image1|image2")
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageViewModel = try layoutTransformer.getDataImage(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertEqual(dataImageViewModel.image, image1)
    }

    func test_getDataImage_withMultipleKeys_secondKeyValid_returnsImage() throws {
        // Arrange
        let image2 = CreativeImage(
            light: "https://rokt.com/image2.png", dark: nil, alt: "alt2", title: nil)
        let offer = get_offer_with_images(["image2": image2])
        let model = DataImageModel<WhenPredicate>(styles: nil, imageKey: "invalidKey|image2")
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageViewModel = try layoutTransformer.getDataImage(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertEqual(dataImageViewModel.image, image2)
    }

    func test_getDataImage_withMultipleKeys_withSpaces_returnsImage() throws {
        // Arrange
        let image2 = CreativeImage(
            light: "https://rokt.com/image2.png", dark: nil, alt: "alt2", title: nil)
        let offer = get_offer_with_images(["image2": image2])
        let model = DataImageModel<WhenPredicate>(styles: nil, imageKey: "invalidKey | image2")
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageViewModel = try layoutTransformer.getDataImage(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertEqual(dataImageViewModel.image, image2)
    }

    func test_getDataImage_withNoValidKeys_returnsNil() throws {
        // Arrange
        let offer = get_offer_with_images([:])
        let model = DataImageModel<WhenPredicate>(
            styles: nil, imageKey: "invalidKey|anotherInvalidKey"
        )
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageViewModel = try layoutTransformer.getDataImage(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertNil(dataImageViewModel.image)
    }

    // MARK: - GetDataImageCarousel

    func test_getDataImageCarousel_withSingleKey_returnsMatchingImages() throws {
        // Arrange
        let image1 = CreativeImage(
            light: "https://rokt.com/carousel_1.png", dark: nil, alt: "alt1", title: nil)
        let image2 = CreativeImage(
            light: "https://rokt.com/carousel_2.png", dark: nil, alt: "alt2", title: nil)
        let otherImage = CreativeImage(
            light: "https://rokt.com/other.png", dark: nil, alt: "alt other", title: nil)
        let offer = get_offer_with_images([
            "carousel.1": image1,
            "carousel.2": image2,
            "other_1": otherImage,
        ])
        let model = DataImageCarouselModel<WhenPredicate>(
            styles: nil, imageKey: "carousel", duration: 5000, a11yLabel: nil
        )
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let viewModel = try layoutTransformer.getDataImageCarousel(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertEqual(viewModel.images.count, 2)
        XCTAssertEqual(viewModel.images, [image1, image2])
    }

    func test_getDataImageCarousel_withMultipleKeys_returnsMatchingImages() throws {
        // Arrange
        let image1 = CreativeImage(
            light: "https://rokt.com/image1.png", dark: nil, alt: "alt1", title: nil)
        let image2 = CreativeImage(
            light: "https://rokt.com/image2.png", dark: nil, alt: "alt2", title: nil)
        let image3 = CreativeImage(
            light: "https://rokt.com/image3.png", dark: nil, alt: "alt3", title: nil)
        let offer = get_offer_with_images([
            "carousel1.1": image1, "carousel2.1": image2, "carousel3.1": image3,
        ])
        let model = DataImageCarouselModel<WhenPredicate>(
            styles: nil,
            imageKey: "invalidKey|carousel2",
            duration: 5000,
            a11yLabel: nil
        )
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageCarouselViewModel = try layoutTransformer.getDataImageCarousel(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertEqual(dataImageCarouselViewModel.images.count, 1)
        XCTAssertEqual(dataImageCarouselViewModel.images[0], image2)
    }

    func test_getDataImageCarousel_withMultipleKeysAndSpaces_returnsMatchingImages() throws {
        // Arrange
        let image1 = CreativeImage(
            light: "https://rokt.com/image1.png", dark: nil, alt: "alt1", title: nil)
        let image2 = CreativeImage(
            light: "https://rokt.com/image2.png", dark: nil, alt: "alt2", title: nil)
        let image3 = CreativeImage(
            light: "https://rokt.com/image3.png", dark: nil, alt: "alt3", title: nil)
        let offer = get_offer_with_images([
            "carousel1.1": image1, "carousel1.2": image2, "carousel3.1": image3,
        ])
        let model = DataImageCarouselModel<WhenPredicate>(
            styles: nil,
            imageKey: "invalidKey | carousel1",
            duration: 5000,
            a11yLabel: nil
        )
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageCarouselViewModel = try layoutTransformer.getDataImageCarousel(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertEqual(dataImageCarouselViewModel.images.count, 2)
        XCTAssertEqual(dataImageCarouselViewModel.images[0], image1)
        XCTAssertEqual(dataImageCarouselViewModel.images[1], image2)
    }

    func test_getDataImageCarousel_withNoMatchingKeys_returnsEmptyArray() throws {
        // Arrange
        let image1 = CreativeImage(
            light: "https://rokt.com/image1.png", dark: nil, alt: "alt1", title: nil)
        let offer = get_offer_with_images(["carousel1.1": image1])
        let model = DataImageCarouselModel<WhenPredicate>(
            styles: nil,
            imageKey: "carousel2|carousel3",
            duration: 5000,
            a11yLabel: nil
        )
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let dataImageCarouselViewModel = try layoutTransformer.getDataImageCarousel(
            model, context: .inner(.generic(offer)))

        // Assert
        XCTAssertEqual(dataImageCarouselViewModel.images.count, 0)
    }

    func test_getCatalogDevicePayButtonModel_basicTransformation() throws {
        // Arrange
        let model = ModelTestData.CatalogDevicePayButtonData.catalogDevicePayButton()
        let catalogItem = get_catalog_item(
            image: CreativeImage(
                light: "https://rokt.com/image.png",
                dark: nil,
                alt: "alt",
                title: nil))
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let transformedModel = try layoutTransformer.getCatalogDevicePayButtonModel(
            style: model.styles,
            children: layoutTransformer.transformChildren(
                model.children, context: .inner(.addToCart(catalogItem))),
            provider: model.provider,
            validatorTriggerConfig: model.validatorTriggerConfig,
            customStateKey: "",
            context: .inner(.addToCart(catalogItem)))

        // Assert
        XCTAssertEqual(transformedModel.provider, .stripe)
        XCTAssertNotNil(transformedModel.catalogItem)
        XCTAssertEqual(transformedModel.catalogItem?.catalogItemId, catalogItem.catalogItemId)
        XCTAssertNotNil(transformedModel.children)
        XCTAssertEqual(transformedModel.children?.count, 1) // Should have one BasicText child
    }

    func test_getCatalogDevicePayButtonModel_providerMapping() throws {
        // Arrange
        let model = ModelTestData.CatalogDevicePayButtonData.catalogDevicePayButton()
        let catalogItem = get_catalog_item(
            image: CreativeImage(
                light: "https://rokt.com/image.png",
                dark: nil,
                alt: "alt",
                title: nil))
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Test different providers
        let providers: [PaymentProvider] = [.stripe, .applePay, .googlePay]

        for provider in providers {
            // Act
            let transformedModel = try layoutTransformer.getCatalogDevicePayButtonModel(
                style: model.styles,
                children: layoutTransformer.transformChildren(
                    model.children, context: .inner(.addToCart(catalogItem))),
                provider: provider,
                validatorTriggerConfig: model.validatorTriggerConfig,
                customStateKey: "",
                context: .inner(.addToCart(catalogItem)))

            // Assert
            XCTAssertEqual(transformedModel.provider, provider)
        }
    }

    func test_getCatalogDevicePayButtonModel_styleTransformation() throws {
        // Arrange
        let model = ModelTestData.CatalogDevicePayButtonData.catalogDevicePayButton()
        let catalogItem = get_catalog_item(
            image: CreativeImage(
                light: "https://rokt.com/image.png",
                dark: nil,
                alt: "alt",
                title: nil))
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let transformedModel = try layoutTransformer.getCatalogDevicePayButtonModel(
            style: model.styles,
            children: layoutTransformer.transformChildren(
                model.children, context: .inner(.addToCart(catalogItem))),
            provider: model.provider,
            validatorTriggerConfig: model.validatorTriggerConfig,
            customStateKey: "",
            context: .inner(.addToCart(catalogItem)))

        // Assert - Check that styles are properly transformed
        XCTAssertNotNil(transformedModel.defaultStyle)
        XCTAssertEqual(transformedModel.defaultStyle?.count, 1) // Should have one breakpoint
        XCTAssertEqual(transformedModel.defaultStyle?[0].spacing?.padding, "5")
        XCTAssertEqual(transformedModel.defaultStyle?[0].spacing?.margin, "24 0")
        XCTAssertEqual(transformedModel.defaultStyle?[0].container?.alignItems, .flexStart)
        XCTAssertEqual(transformedModel.defaultStyle?[0].container?.justifyContent, .center)
        XCTAssertEqual(transformedModel.defaultStyle?[0].border?.borderRadius, 4)
        XCTAssertEqual(
            transformedModel.defaultStyle?[0].background?.backgroundColor?.light, "#CC0000")
    }

    func test_getCatalogDevicePayButtonModel_invalidContext_throwsError() throws {
        // Arrange
        let model = ModelTestData.CatalogDevicePayButtonData.catalogDevicePayButton()
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act & Assert - Should throw error when context doesn't have catalog item
        XCTAssertThrowsError(
            try layoutTransformer.getCatalogDevicePayButtonModel(
                style: model.styles,
                children: layoutTransformer.transformChildren(
                    model.children, context: .inner(.generic(nil))),
                provider: model.provider,
                validatorTriggerConfig: model.validatorTriggerConfig,
                customStateKey: "",
                context: .inner(.generic(nil)))) { error in
            XCTAssertTrue(error is LayoutTransformerError)
        }
    }

    func test_getCatalogDevicePayButtonModel_childrenTransformation() throws {
        // Arrange
        let model = ModelTestData.CatalogDevicePayButtonData.catalogDevicePayButton()
        let catalogItem = get_catalog_item(
            image: CreativeImage(
                light: "https://rokt.com/image.png",
                dark: nil,
                alt: "alt",
                title: nil))
        let layoutTransformer = LayoutTransformer(
            layoutPlugin: get_layout_plugin(layout: nil, slots: []))

        // Act
        let transformedModel = try layoutTransformer.getCatalogDevicePayButtonModel(
            style: model.styles,
            children: layoutTransformer.transformChildren(
                model.children, context: .inner(.addToCart(catalogItem))),
            provider: model.provider,
            validatorTriggerConfig: model.validatorTriggerConfig,
            customStateKey: "",
            context: .inner(.addToCart(catalogItem)))

        // Assert - Check that children are properly transformed
        XCTAssertNotNil(transformedModel.children)
        XCTAssertEqual(transformedModel.children?.count, 1)

        // Check that the child is a BasicText component
        if case .basicText(let textModel) = transformedModel.children?[0] {
            XCTAssertEqual(textModel.boundValue, "Add to order")
        } else {
            XCTFail("Expected BasicText child")
        }
    }

    //MARK: mock objects

    func get_layout_plugin(layout: LayoutSchemaModel?, slots: [SlotModel]) -> LayoutPlugin {
        return get_mock_layout_plugin(layout: layout, slots: slots)
    }

    func get_slot(
        responseOptionList: ResponseOptionList?,
        layoutVariant: CreativeResponseModel<LayoutSchemaModel, WhenPredicate>? = nil
    ) -> SlotModel {
        SlotModel(
            instanceGuid: "",
            offer: .mock(responseOptionList: responseOptionList, token: "creative-token"),
            layoutVariant: layoutVariant == nil
                ? nil
                : LayoutVariantModel(
                    layoutVariantSchema: .creativeResponse(layoutVariant!), moduleName: ""),
            jwtToken: "slot-token")
    }

    func get_offer_with_images(_ images: [String: CreativeImage]?) -> OfferModel {
        let creative = CreativeModel(
            referralCreativeId: "referralCreativeId",
            instanceGuid: "instanceGuid",
            copy: [:],
            images: images,
            links: nil,
            responseOptionsMap: nil,
            jwtToken: "token")
        return OfferModel(
            campaignId: "campaignId",
            creative: creative,
            catalogItems: nil)
    }

    func get_catalog_item(image: CreativeImage) -> CatalogItem {
        return CatalogItem(
            images: ["creativeImage": image],
            catalogItemId: "catalogItemId",
            cartItemId: "cartItemId",
            instanceGuid: "instanceGuid",
            title: "title",
            description: "description",
            price: 14.99,
            priceFormatted: "$14.99",
            originalPrice: 14.99,
            originalPriceFormatted: "$14.99",
            currency: "USD",
            signalType: "mockSignalType",
            url: "https://www.example.com",
            minItemCount: 1,
            maxItemCount: 10,
            preSelectedQuantity: 1,
            providerData: "861425",
            urlBehavior: "mockUrlBehavior",
            positiveResponseText: "Add to order",
            negativeResponseText: "Dismiss",
            addOns: ["addon1", "addon2"],
            copy: ["key1": "value1", "key2": "value2"],
            inventoryStatus: nil,
            linkedProductId: "linked",
            token: "catalog1Token")
    }
}
