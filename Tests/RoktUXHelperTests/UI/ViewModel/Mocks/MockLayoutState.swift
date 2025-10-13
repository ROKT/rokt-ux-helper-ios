import Foundation
import SwiftUI
import Combine
@testable import RoktUXHelper
import DcuiSchema

@available(iOS 15, *)
class MockLayoutState: LayoutStateRepresenting {
    var items: [String: Any] = [:]
    var itemsPublisher: CurrentValueSubject<[String: Any], Never> = .init([:])
    var actionCollection: ActionCollecting = ActionCollection()
    var imageLoader: RoktUXImageLoader?
    var colorMode: RoktUXConfig.ColorMode?
    var config: RoktUXConfig?
    var initialPluginViewState: RoktPluginViewState?
    var validationCoordinator: FormValidationCoordinating = FormValidationCoordinator()
    private var currentLayoutType: RoktUXPlacementLayoutCode = .overlayLayout
    var shouldCloseOnComplete: Bool = false
    var mockBreakpointIndex: Int = 0

    func setLayoutType(_ type: RoktUXPlacementLayoutCode) {
        currentLayoutType = type
    }

    func layoutType() -> RoktUXPlacementLayoutCode {
        return currentLayoutType
    }

    func closeOnComplete() -> Bool {
        return shouldCloseOnComplete
    }

    func getGlobalBreakpointIndex(_ width: CGFloat?) -> Int {
        return mockBreakpointIndex
    }

    func capturePluginViewState(offerIndex: Int?, dismiss: Bool?) {
        // No-op for mock
    }

    func publishStateChange() {
        // No-op for mock
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    static func == (lhs: MockLayoutState, rhs: MockLayoutState) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
