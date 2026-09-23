import XCTest
@testable import RoktUXHelper
import DcuiSchema

/// Nesting-depth behaviour of the layout transform.
///
/// The transform is a recursive descent, so its stack cost grows with how deeply a layout nests.
/// A simulator main thread is 8 MB but a device main thread is 1 MB, which is why these tests run
/// the transform on a deliberately narrow thread — a simulator-sized stack hides the problem
/// entirely.
@available(iOS 15, *)
final class LayoutNestingDepthTests: XCTestCase {

    /// Roughly a device main thread, and well under it, so a regression fails here rather than in
    /// a partner's app.
    private static let deviceSizedStack = 512 * 1024

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

    /// Runs `body` on a thread with a device-sized stack and blocks until it finishes.
    private func onDeviceSizedStack<T>(_ body: @escaping () throws -> T) throws -> T {
        var result: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)
        let thread = Thread {
            defer { semaphore.signal() }
            result = Result { try body() }
        }
        thread.stackSize = Self.deviceSizedStack
        thread.start()
        semaphore.wait()
        return try XCTUnwrap(result).get()
    }

    func test_deeply_nested_layout_transforms_on_a_device_sized_stack() throws {
        let layout = try nestedLayout(depth: 40)
        let transformer = LayoutTransformer(layoutPlugin: get_mock_layout_plugin(layout: layout))

        let model = try onDeviceSizedStack { try transformer.transform() }

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
}
