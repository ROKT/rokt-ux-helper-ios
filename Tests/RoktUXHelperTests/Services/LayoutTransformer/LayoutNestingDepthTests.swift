import XCTest
@testable import RoktUXHelper
import DcuiSchema

/// Nesting-depth behaviour of the layout transform.
///
/// The transform is a recursive descent, so its stack cost grows with how deeply a layout nests.
/// Both entry points that run it in production route through `WideStack`, which spawns its own
/// dedicated 8 MB thread regardless of the caller's own stack size: `transform()` wraps the initial
/// build (`RoktUX.displayLayout`), and the catalog `childBuilder` wraps the per-item rebuild at
/// render time (`LayoutTransformer.swift`). So neither path is actually exposed to a narrow,
/// device-sized stack today — simulating one here would test a risk that doesn't exist in the
/// shipped code. What these tests pin instead is the depth-cap boundary itself, on both entry
/// points: a layout right at the cap still transforms, and one past it still throws
/// `layoutTooDeep`. The stack margin `WideStack` provides is covered separately, statically, by
/// `tools/frame_budget.py`.
@available(iOS 15, *)
final class LayoutNestingDepthTests: XCTestCase {

    /// `Row` wrapping `Row` … wrapping a leaf `RichText`, `depth` levels deep.
    private func nestedRows(depth: Int) -> [String: Any] {
        var node: [String: Any] = ["type": "RichText", "node": ["value": "Example"]]
        for _ in 0..<depth {
            node = ["type": "Row", "node": ["children": [node]]]
        }
        return node
    }

    private func nestedLayout(depth: Int) throws -> LayoutSchemaModel {
        let data = try JSONSerialization.data(withJSONObject: nestedRows(depth: depth))
        return try JSONDecoder().decode(LayoutSchemaModel.self, from: data)
    }

    /// The real production entry point: `transform()` hands its recursive work to `WideStack`, so
    /// this only has to prove it still succeeds right up to the enforced depth cap.
    func test_deeply_nested_layout_transforms_up_to_the_depth_cap() throws {
        let layout = try nestedLayout(depth: LayoutDepthCounter.maxNestingDepth - 1)
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(layout: layout))

        let model = try transformer.transform()

        XCTAssertNotNil(model)
    }

    func test_layout_exceeding_max_nesting_depth_throws_layoutTooDeep() throws {
        // Just past the guard. Not far past it: Foundation's JSON parser refuses more than
        // 512 nested containers, which caps an authored layout at roughly 170 levels anyway.
        let layout = try nestedLayout(depth: LayoutDepthCounter.maxNestingDepth + 6)
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(layout: layout))

        XCTAssertThrowsError(try transformer.transform()) { error in
            XCTAssertEqual(
                error as? LayoutTransformerError,
                .layoutTooDeep(depth: LayoutDepthCounter.maxNestingDepth)
            )
        }
    }

    private func nestedCatalogTemplate(depth: Int) throws -> LayoutSchemaModel {
        var template: [String: Any] = ["type": "BasicText", "node": ["value": "Example"]]
        for _ in 0..<depth {
            template = ["type": "Column", "node": ["children": [template]]]
        }
        return try JSONDecoder().decode(
            LayoutSchemaModel.self,
            from: JSONSerialization.data(withJSONObject: [
                "type": "CatalogCombinedCollection",
                "node": ["template": template]
            ])
        )
    }

    /// The catalog template's own build path, right at the depth cap.
    func test_deeply_nested_catalog_template_transforms_up_to_the_depth_cap() throws {
        let layout = try nestedCatalogTemplate(depth: LayoutDepthCounter.maxNestingDepth - 1)
        let offer = OfferModel.mock(catalogItems: [CatalogItem.mock()])
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())

        let model = try transformer.transform(layout, context: .inner(.generic(offer)))

        guard case .catalogCombinedCollection = model else {
            return XCTFail("Expected a catalogCombinedCollection view model, got \(model)")
        }
    }

    /// A catalog template is built twice: once inside the transform, and again at render time when
    /// the selected item changes. Only the render-time rebuild may swallow a failure — the initial
    /// build has to surface it, or an over-deep template renders as an empty collection while the
    /// transform reports success.
    func test_over_deep_catalog_template_fails_the_initial_transform() throws {
        let layout = try nestedCatalogTemplate(depth: LayoutDepthCounter.maxNestingDepth + 6)
        let offer = OfferModel.mock(catalogItems: [CatalogItem.mock()])
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())

        XCTAssertThrowsError(try transformer.transform(layout, context: .inner(.generic(offer)))) { error in
            XCTAssertEqual(
                error as? LayoutTransformerError,
                .layoutTooDeep(depth: LayoutDepthCounter.maxNestingDepth)
            )
        }
    }
}
