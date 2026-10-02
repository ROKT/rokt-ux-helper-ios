import XCTest
import SwiftUI
import ViewInspector
import SnapshotTesting
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15.0, *)
final class TestBasicTextComponent: XCTestCase {

    func test_capitalize_follows_css_word_boundaries() {
        // Expected values match how a browser renders `text-transform: capitalize`.
        let cases = [
            ("(hello)", "(Hello)"),
            ("'thanks'", "'Thanks'"),
            ("hello-world", "Hello-World"),
            ("e-mail", "E-Mail"),
            ("«quoted» text", "«Quoted» Text"),
            ("123abc", "123abc"),
            ("x2y z", "X2y Z"),
            ("hello_world", "Hello_world"),
            ("don't", "Don't"),
            ("don\u{2019}t", "Don\u{2019}t"),
            ("rock 'n' roll", "Rock 'N' Roll"),
            ("iPhone USA", "IPhone USA"),
            ("hello\nworld", "Hello\nWorld")
        ]
        for (input, expected) in cases {
            XCTAssertEqual(BasicTextViewModel.transform(input, using: .capitalize), expected, input)
        }
    }

    func test_style_state_transform_starts_from_authored_text() {
        let pressedUppercase = BasicTextViewModel(
            value: "hello world",
            defaultStyle: [textStyle(transform: nil)],
            pressedStyle: [textStyle(transform: .uppercase)],
            hoveredStyle: nil,
            disabledStyle: nil,
            layoutState: nil,
            diagnosticService: nil
        )
        XCTAssertEqual(pressedUppercase.boundValue, "hello world")
        pressedUppercase.styleState = .pressed
        XCTAssertEqual(pressedUppercase.boundValue, "HELLO WORLD")
        pressedUppercase.styleState = .default
        XCTAssertEqual(pressedUppercase.boundValue, "hello world")

        let pressedCapitalize = BasicTextViewModel(
            value: "hello world",
            defaultStyle: [textStyle(transform: .uppercase)],
            pressedStyle: [textStyle(transform: .capitalize)],
            hoveredStyle: nil,
            disabledStyle: nil,
            layoutState: nil,
            diagnosticService: nil
        )
        XCTAssertEqual(pressedCapitalize.boundValue, "HELLO WORLD")
        pressedCapitalize.styleState = .pressed
        XCTAssertEqual(pressedCapitalize.boundValue, "Hello World")
        pressedCapitalize.styleState = .default
        XCTAssertEqual(pressedCapitalize.boundValue, "HELLO WORLD")
    }

    private func textStyle(transform: TextTransform?) -> BasicTextStyle {
        BasicTextStyle(
            dimension: nil,
            flexChild: nil,
            spacing: nil,
            background: nil,
            text: TextStylingProperties(
                textColor: nil,
                fontSize: nil,
                fontFamily: nil,
                fontWeight: nil,
                lineHeight: nil,
                horizontalTextAlign: nil,
                baselineTextAlign: nil,
                fontStyle: nil,
                textTransform: transform,
                letterSpacing: nil,
                textDecoration: nil,
                lineLimit: nil
            )
        )
    }

    func test_basic_text() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.basicText(try get_model()))
        
        let text = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(BasicTextComponent.self)
            .actualView()
            .inspect()
            .text()
        
        // test custom modifier class
        let paddingModifier = try text.modifier(PaddingModifier.self)
        XCTAssertEqual(try paddingModifier.actualView().padding, FrameAlignmentProperty(top: 10, right: 5, bottom: 1, left: 10))
        
        // test the effect of custom modifier
        let padding = try text.padding()
        XCTAssertEqual(padding, EdgeInsets(top: 10.0, leading: 10.0, bottom: 17.0, trailing: 5.0))
        
        XCTAssertEqual(try text.attributes().foregroundColor(), Color(hex: "#AABBCC"))
        
        XCTAssertEqual(try text.string(), "ORDER Number: Uk171359906")
        
        // alignment self modifier
        let alignSelfModifier = try text.modifier(AlignSelfModifier.self)
        XCTAssertEqual(try alignSelfModifier.actualView().wrapperAlignment?.horizontal, .center)
        
        // frame
        let flexFrame = try text.flexFrame()
        XCTAssertEqual(flexFrame.minHeight, 48)
        XCTAssertEqual(flexFrame.maxHeight, 48)
    }
    
    func test_basicText_computedProperties_usesModelProperties() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.basicText(try get_model()))
        
        let sut = try view.inspect().view(TestPlaceHolder.self)
            .view(EmbeddedComponent.self)
            .vStack()[0]
            .view(LayoutSchemaComponent.self)
            .view(BasicTextComponent.self)
            .actualView()
        
        let model = sut.model
        
        XCTAssertEqual(sut.style, model.currentStylingProperties)
        XCTAssertEqual(sut.dimensionStyle, model.currentStylingProperties?.dimension)
        XCTAssertEqual(sut.flexStyle, model.currentStylingProperties?.flexChild)
        XCTAssertEqual(sut.backgroundStyle, model.currentStylingProperties?.background)
        XCTAssertEqual(sut.spacingStyle, model.currentStylingProperties?.spacing)
        
        XCTAssertNil(sut.lineLimit)
        XCTAssertEqual(sut.lineHeight, 0)
        XCTAssertEqual(sut.lineHeightPadding, 0)
        
        XCTAssertEqual(sut.verticalAlignment, .top)
        XCTAssertEqual(sut.horizontalAlignment, .start)
        
        XCTAssertEqual(sut.stateReplacedValue, "ORDER Number: Uk171359906")
    }

    func testSnapshot() throws {
        let view = TestPlaceHolder(layout: LayoutSchemaViewModel.basicText(try get_model()))
            .frame(width: 350)
        
        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(
            of: hostingController,
            as: .image(on: snapshotDevice, precision: snapshotPrecision, perceptualPrecision: snapshotPerceptualPrecision)
        )
    }
    
    func get_model() throws -> BasicTextViewModel {
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())
        return try transformer.getBasicText(ModelTestData.TextData.basicText(), context: .outer([]))
    }
}
