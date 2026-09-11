import DcuiSchema
import XCTest
@testable import RoktUXHelper

@MainActor
final class TestInlineContainerChild: XCTestCase {
    func testInteractionStylesRetainTheirLastBreakpointWhenShorterThanDefaults() throws {
        try assertStyleSelection(defaults: [0.7, 0.8, 0.9], selected: [0.2, 0.4], expected: 0.4)
    }

    func testInteractionStylesUseBreakpointsBeyondTheDefaultArray() throws {
        try assertStyleSelection(defaults: [0.9], selected: [0.2, 0.4, 0.6], expected: 0.6)
    }

    func testMissingInteractionStylesFallBackToTheDefaultBreakpoint() throws {
        try assertStyleSelection(defaults: [0.7, 0.8, 0.9], selected: nil, expected: 0.9)
    }

    func testEmptyInteractionStyleArraysRemainUnstyled() throws {
        try assertStyleSelection(defaults: [0.7, 0.8, 0.9], selected: [], expected: nil)
    }

    private func assertStyleSelection(defaults: [Float], selected: [Float]?, expected: Float?,
                                      file: StaticString = #filePath, line: UInt = #line) throws {
        let layoutState = LayoutState()
        layoutState.items[LayoutState.breakPointsSharedKey] = ["small": 320, "large": 700] as BreakPoint
        XCTAssertEqual(layoutState.getGlobalBreakpointIndex(800), 2, file: file, line: line)
        for kind in [ActionKind.link, .toggle] {
            for state in [StyleState.pressed, .hovered, .disabled] {
                let child = try makeChild(kind, defaults: defaults, selected: selected, state: state,
                                          layoutState: layoutState)
                XCTAssertEqual(child.spanStyle(width: 800).opacity, expected, "\(kind) \(state)", file: file, line: line)
                child.texts[0].styleState = .default
                XCTAssertEqual(child.spanStyle(width: 800).opacity, defaults.last, file: file, line: line)
            }
        }
    }

    private func makeChild(_ kind: ActionKind, defaults: [Float], selected: [Float]?, state: StyleState,
                           layoutState: LayoutState) throws -> InlineContainerChild {
        let label = BasicTextViewModel(value: "Change", defaultStyle: nil, pressedStyle: nil,
                                       hoveredStyle: nil, disabledStyle: nil, layoutState: nil, diagnosticService: nil)
        label.styleState = state
        switch kind {
        case .link:
            let values = try styles(selected, as: StaticLinkStyles.self)
            let model = StaticLinkViewModel(children: nil, src: "https://example.com/details", open: .externally,
                                            defaultStyle: try styles(defaults, as: StaticLinkStyles.self),
                                            pressedStyle: state == .pressed ? values : nil,
                                            hoveredStyle: state == .hovered ? values : nil,
                                            disabledStyle: state == .disabled ? values : nil,
                                            layoutState: layoutState, eventService: nil)
            return .link(model, label: [label])
        case .toggle:
            let values = try styles(selected, as: ToggleButtonStateTriggerStyle.self)
            let model = ToggleButtonViewModel(children: nil, customStateKey: "details",
                                              defaultStyle: try styles(defaults, as: ToggleButtonStateTriggerStyle.self),
                                              pressedStyle: state == .pressed ? values : nil,
                                              hoveredStyle: state == .hovered ? values : nil,
                                              disabledStyle: state == .disabled ? values : nil, layoutState: layoutState)
            return .toggle(model, label: [label])
        }
    }

    private func styles<T: Decodable>(_ values: [Float]?, as type: T.Type) throws -> [T]? {
        guard let values else { return nil }
        return try values.map { value in
            let data = try JSONSerialization.data(withJSONObject: ["container": ["opacity": value]])
            return try JSONDecoder().decode(type, from: data)
        }
    }

    private enum ActionKind { case link, toggle }
}
