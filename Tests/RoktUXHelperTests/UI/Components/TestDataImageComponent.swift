import XCTest
import SwiftUI
import ViewInspector
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15.0, *)
final class TestDataImageComponent: XCTestCase {

    func test_data_image() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model()))
        
        let image = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
            .inspect()
            .find(AsyncImageView.self)
        
        // test custom modifier class
        let paddingModifier = try image.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 18, right: 24, bottom: 0, left: 24))
        
        // test the effect of custom modifier
        let padding = try image.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 18.0, leading: 24.0, bottom: 0.0, trailing: 24.0))
    }    
    
    func test_data_image_failed() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model(isValid: false)))
        
        let image = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
            .inspect()
        // Invalid Image should be removed from view
        XCTAssertNil(try? image.find(AsyncImageView.self))
    }

    func test_data_image_withGenericBackendAlt_isHiddenFromAccessibility() throws {
        let imageURL = "https://docs.rokt.com/assets/images/embedded-placement-1-5ab04a718fe7dda94ac24aa7b89aac92.png"
        let slot = get_slot(image: imageURL, alt: "image")
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(slots: [slot]))
        let model = try transformer.getDataImage(
            ModelTestData.DataImageData.dataImage(),
            context: .inner(.generic(slot.offer!))
        )
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(model))

        let asyncImage = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
            .inspect()
            .find(AsyncImageView.self)
            .asyncImage()

        XCTAssertEqual(try asyncImage.accessibilityLabel().string(), "")
        XCTAssertEqual(try asyncImage.accessibilityHidden(), true)
    }

    func test_data_image_with_fallback() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model(isValid: true, isFallback: true)))

        _ = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
            .inspect()
            .find(AsyncImageView.self)
    }

    func test_dataImage_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(try get_model()))
        
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
        
        let model = sut.model
        
        XCTAssertEqual(sut.dimensionStyle, model.defaultStyle?.first?.dimension)
        XCTAssertEqual(sut.flexStyle, model.defaultStyle?.first?.flexChild)
        XCTAssertEqual(sut.backgroundStyle, model.defaultStyle?.first?.background)
        XCTAssertEqual(sut.spacingStyle, model.defaultStyle?.first?.spacing)
        
        XCTAssertEqual(sut.verticalAlignment, .center)
        XCTAssertEqual(sut.horizontalAlignment, .center)
        
        let asyncImage = try sut.inspect().find(AsyncImageView.self).actualView()
        // nil url is converted to empty string
        XCTAssertEqual(asyncImage.imageUrl,
                       ThemeUrl(
                           light: "https://docs.rokt.com/assets/images/embedded-placement-1-5ab04a718fe7dda94ac24aa7b89aac92.png",
                           dark: ""
                       ))
    }

    func test_dataImageScale_defaultsToFit() throws {
        XCTAssertEqual(try get_async_image_scale(for: nil), .fit)
    }

    func test_dataImageScale_usesConfiguredScale() throws {
        XCTAssertEqual(try get_async_image_scale(for: .fit), .fit)
        XCTAssertEqual(try get_async_image_scale(for: .fill), .fill)
        XCTAssertEqual(try get_async_image_scale(for: .crop), .crop)
    }

    func test_dataImageClipsToBounds_forFillScale() throws {
        XCTAssertTrue(try get_data_image_component(for: .fill).clipsToBounds)
    }

    func test_dataImageClipsToBounds_forBorderRadius() throws {
        XCTAssertTrue(try get_data_image_component(for: nil, borderRadius: 16).clipsToBounds)
    }

    func test_dataImageClipsToBounds_defaultsToFalse() throws {
        XCTAssertFalse(try get_data_image_component(for: nil).clipsToBounds)
    }

    func test_dataImageDefaultWidth_defaultsToWrapContentForFitScale() throws {
        XCTAssertEqual(try get_data_image_component(for: .fit).defaultWidth, .wrapContent)
    }

    func test_dataImageDefaultWidth_usesFitWidthForFillScale() throws {
        XCTAssertEqual(try get_data_image_component(for: .fill).defaultWidth, .fitWidth)
    }

    func test_dataImageDefaultWidth_usesFitWidthForCropScale() throws {
        XCTAssertEqual(try get_data_image_component(for: .crop).defaultWidth, .fitWidth)
    }

    func get_model(isValid: Bool = true, isFallback: Bool = false) throws -> DataImageViewModel {
        let validImage = "https://docs.rokt.com/assets/images/embedded-placement-1-5ab04a718fe7dda94ac24aa7b89aac92.png"
        let invalidImage = ""
        let transformer = LayoutTransformer(
            layoutPlugin: get_mock_layout_plugin(slots: [get_slot(image: isValid ? validImage : invalidImage)])
        )
        return try transformer.getDataImage(
            isFallback ? ModelTestData.DataImageData.dataImageWithFallback() : ModelTestData.DataImageData.dataImage(),
            context: .inner(.generic(get_slot(image: isValid ? validImage : invalidImage).offer!))
        )
    }

    func get_slot(image: String, alt: String? = "") -> SlotModel {
        return SlotModel(instanceGuid: "",
                         offer: OfferModel(campaignId: "", creative:
                                            CreativeModel(referralCreativeId: "",
                                                          instanceGuid: "",
                                                          copy: [:],
                                                          images: [
                                                              "creativeImage": CreativeImage(
                                                                  light: image,
                                                                  dark: nil,
                                                                  alt: alt,
                                                                  title: nil
                                                              )
                                                          ],
                                                          links: nil,
                                                          responseOptionsMap: nil,
                                                          jwtToken: "creative-token"),
                                           catalogItems: nil,
                                           catalogItemGroup: nil,
                                           transactionData: nil),
                         layoutVariant: nil,
                         jwtToken: "slot-token")
    }

    func get_async_image_scale(for scale: DcuiSchema.ImageScale?) throws -> ImageRenderScale? {
        try get_data_image_component(for: scale)
            .inspect()
            .find(AsyncImageView.self)
            .actualView()
            .scale
    }

    func get_data_image_component(
        for scale: DcuiSchema.ImageScale?,
        borderRadius: Float? = nil
    ) throws -> DataImageViewComponent {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.dataImage(
            get_model(scale: scale, borderRadius: borderRadius)
        ))

        return try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(DataImageViewComponent.self)
            .actualView()
    }

    func get_model(scale: DcuiSchema.ImageScale?, borderRadius: Float? = nil) -> DataImageViewModel {
        DataImageViewModel(
            image: CreativeImage(
                light: "https://docs.rokt.com/assets/images/embedded-placement-1-5ab04a718fe7dda94ac24aa7b89aac92.png",
                dark: nil,
                alt: "",
                title: nil
            ),
            defaultStyle: [
                DataImageStyles(
                    background: nil,
                    border: borderRadius.map {
                        BorderStylingProperties(borderRadius: $0,
                                                borderColor: nil,
                                                borderWidth: nil,
                                                borderStyle: nil)
                    },
                    dimension: nil,
                    image: scale.map { ImageStylingProperties(scale: $0) },
                    flexChild: nil,
                    spacing: nil
                )
            ],
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            layoutState: nil
        )
    }
}
