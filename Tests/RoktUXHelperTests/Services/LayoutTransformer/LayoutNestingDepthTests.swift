import XCTest
@testable import RoktUXHelper
import DcuiSchema

/// Nesting-depth behaviour of the layout transform.
///
/// The transform is a recursive descent, so its stack cost grows with how deeply a layout nests.
/// Two call sites each spawn their own dedicated 8 MB `WideStack` thread, independent of whatever
/// thread calls them: `transform()`'s initial build (`RoktUX.displayLayout`), and the catalog
/// `childBuilder`'s render-time rebuild (both in `LayoutTransformer.swift`). Calling either from a
/// narrow, device-sized thread here doesn't simulate today's real risk — `WideStack` already
/// neutralises it — but it earns its place as a regression guard: if a future change ever removed
/// or bypassed either `WideStack.run` call, the recursion would fall back to running on the
/// caller's own thread, and the matching test below would then fail on a narrow one instead of
/// quietly passing on the test runner's wide one. The catalog template's *initial* build has no
/// `WideStack.run` of its own — it always runs already inside `transform()`'s — so it's tested on
/// the default thread instead; seeing it on a narrow thread would only test whether the raw
/// recursion fits there, not any integration this file is responsible for pinning. The stack margin
/// `WideStack` provides is covered separately, statically, by `tools/frame_budget.py`.
@available(iOS 15, *)
final class LayoutNestingDepthTests: XCTestCase {

    /// Small enough that a layout at the depth cap reliably overflows it if `WideStack` is ever
    /// removed or bypassed, and large enough that it does not — both confirmed empirically: 512 KB
    /// (closer to a real device main thread) is over the transform's own per-level cost and never
    /// trips even without `WideStack`; 128 KB crashes even with `WideStack` present, because
    /// `transform()`'s own post-processing pass (`AttributedStringTransformer`, deliberately not
    /// `WideStack`-protected — see below) also needs headroom on the caller's thread. 256 KB is the
    /// value that reliably crashed without `WideStack` while passing with it.
    private static let narrowStackSize = 256 * 1024

    /// Runs `body` on a thread with a device-sized stack and blocks until it finishes.
    private func onNarrowStack<T>(_ body: @escaping () throws -> T) throws -> T {
        var result: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)
        let thread = Thread {
            defer { semaphore.signal() }
            result = Result { try body() }
        }
        thread.stackSize = Self.narrowStackSize
        thread.start()
        semaphore.wait()
        return try XCTUnwrap(result).get()
    }

    /// `Row` wrapping `Row` … wrapping a leaf `RichText`, `depth` levels deep.
    private func nestedRows(depth: Int) -> [String: Any] {
        var node: [String: Any] = ["type": "RichText", "node": ["value": "Example"]]
        for _ in 0..<depth {
            node = ["type": "Row", "node": ["children": [node]]]
        }
        return node
    }

    /// Decoding is recursive too, so it deliberately happens on the caller's (wide) stack — a
    /// decode failure inside the narrow thread would look like a transform failure.
    private func nestedLayout(depth: Int) throws -> LayoutSchemaModel {
        let data = try JSONSerialization.data(withJSONObject: nestedRows(depth: depth))
        return try JSONDecoder().decode(LayoutSchemaModel.self, from: data)
    }

    /// The real production entry point: `transform()` hands its recursive work to `WideStack`. This
    /// proves it still succeeds right up to the enforced depth cap, from a narrow calling thread —
    /// which only stays true because `WideStack` is actually in the call chain.
    func test_deeply_nested_layout_transforms_up_to_the_depth_cap() throws {
        let layout = try nestedLayout(depth: LayoutDepthCounter.maxNestingDepth - 1)
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(layout: layout))

        let model = try onNarrowStack { try transformer.transform() }

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

    /// The catalog template's own initial-build path, right at the depth cap. In production this
    /// call always runs already inside `transform()`'s own `WideStack` thread — it has no
    /// `WideStack.run` of its own to lose — so, unlike the other tests in this file, it's
    /// deliberately called on the default thread rather than a narrow one: wrapping it would test
    /// whether the raw recursion fits in that thread, which isn't the integration this file is
    /// pinning. The no-arg entry point above already covers that `WideStack` handoff.
    func test_deeply_nested_catalog_template_transforms_up_to_the_depth_cap() throws {
        let layout = try nestedCatalogTemplate(depth: LayoutDepthCounter.maxNestingDepth - 1)
        let offer = OfferModel.mock(catalogItems: [CatalogItem.mock(catalogItemId: "first")])
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())

        let model = try transformer.transform(layout, context: .inner(.generic(offer)))

        guard case .catalogCombinedCollection = model else {
            return XCTFail("Expected a catalogCombinedCollection view model, got \(model)")
        }
    }

    /// The catalog template's *separate* rebuild path: `CatalogCombinedCollectionViewModel`'s
    /// `childBuilder` wraps its own `WideStack.run` independent of the initial build's, since the
    /// rebuild happens later, at render time, when the selected item changes — so it needs its own
    /// dedicated test rather than being assumed to be covered by the initial build above.
    func test_deeply_nested_catalog_template_rebuild_transforms_up_to_the_depth_cap() throws {
        let layout = try nestedCatalogTemplate(depth: LayoutDepthCounter.maxNestingDepth - 1)
        let firstItem = CatalogItem.mock(catalogItemId: "first")
        let secondItem = CatalogItem.mock(catalogItemId: "second")
        let offer = OfferModel.mock(catalogItems: [firstItem, secondItem])
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin())

        let model = try transformer.transform(layout, context: .inner(.generic(offer)))
        guard case .catalogCombinedCollection(let viewModel) = model else {
            return XCTFail("Expected a catalogCombinedCollection view model, got \(model)")
        }

        let rebuilt = try onNarrowStack { viewModel.rebuildChildren(for: secondItem) }

        XCTAssertTrue(rebuilt)
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
