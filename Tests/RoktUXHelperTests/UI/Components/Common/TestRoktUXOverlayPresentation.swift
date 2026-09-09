import XCTest
import UIKit
@testable import RoktUXHelper

/// Covers bounded presenter retries for overlay and bottom sheet placements.
@available(iOS 15.0, *)
final class TestRoktUXOverlayPresentation: XCTestCase {

    func testPresentsImmediatelyWhenTopViewControllerIsAvailable() {
        let ux = RoktUX()
        let viewController = UIViewController()
        var resolveCalls = 0
        ux.topViewControllerProvider = {
            resolveCalls += 1
            return viewController
        }
        ux.scheduleOverlayRetry = { _, _ in
            XCTFail("must not retry when a presenter is available")
        }
        var failure: RoktUXEvent?
        ux.onRoktEvent = { failure = $0 }

        var presentedViewController: UIViewController?
        ux.attemptOverlayPresentation(eventService: nil, onUnload: {
            XCTFail("must not unload")
        }, present: {
            presentedViewController = $0
        })

        XCTAssertTrue(presentedViewController === viewController)
        XCTAssertEqual(resolveCalls, 1)
        XCTAssertNil(failure)
    }

    func testRetriesUntilTopViewControllerBecomesAvailable() {
        let ux = RoktUX()
        var currentTime: TimeInterval = 0
        ux.overlayPresentationTimeProvider = { currentTime }
        var scheduledRetries = 0
        ux.scheduleOverlayRetry = { delay, work in
            scheduledRetries += 1
            currentTime += delay
            work()
        }
        let viewController = UIViewController()
        var resolveCalls = 0
        ux.topViewControllerProvider = {
            resolveCalls += 1
            return resolveCalls >= 3 ? viewController : nil
        }
        var unloadCount = 0
        var failure: RoktUXEvent?
        ux.onRoktEvent = { failure = $0 }

        var presentedViewController: UIViewController?
        ux.attemptOverlayPresentation(eventService: nil, onUnload: {
            unloadCount += 1
        }, present: {
            presentedViewController = $0
        })

        XCTAssertTrue(presentedViewController === viewController)
        XCTAssertEqual(resolveCalls, 3)
        XCTAssertEqual(scheduledRetries, 2)
        XCTAssertEqual(unloadCount, 0)
        XCTAssertNil(failure)
    }

    func testTransitionAttemptsDoNotReducePresenterRetryBudget() {
        let ux = RoktUX()
        ux.overlayMaxPresenterRetries = 2
        ux.overlayPresenterRetryDelay = 0
        ux.scheduleOverlayRetry = { _, work in work() }
        var resolveCalls = 0
        ux.topViewControllerProvider = {
            resolveCalls += 1
            return nil
        }

        ux.attemptOverlayPresentation(eventService: nil,
                                      onUnload: {},
                                      transitionAttempt: 3,
                                      present: { _ in
            XCTFail("must not present without a view controller")
        })

        XCTAssertEqual(resolveCalls, ux.overlayMaxPresenterRetries + 1)
    }

    func testExhaustionEmitsOneFailureWithEventMetadata() {
        let ux = RoktUX()
        ux.overlayMaxPresenterRetries = 3
        ux.overlayPresenterRetryDelay = 0
        ux.scheduleOverlayRetry = { _, work in work() }
        var resolveCalls = 0
        ux.topViewControllerProvider = {
            resolveCalls += 1
            return nil
        }
        let eventService = get_mock_event_processor()
        var unloadCount = 0
        var failures: [RoktUXEvent.LayoutFailure] = []
        ux.onRoktEvent = { event in
            if let failure = event as? RoktUXEvent.LayoutFailure {
                failures.append(failure)
            }
        }

        ux.attemptOverlayPresentation(eventService: eventService, onUnload: {
            unloadCount += 1
        }, present: { _ in
            XCTFail("must not present without a view controller")
        })

        XCTAssertEqual(resolveCalls, ux.overlayMaxPresenterRetries + 1)
        XCTAssertEqual(unloadCount, 1)
        XCTAssertEqual(failures.count, 1)
        XCTAssertEqual(failures.first?.layoutId, mockPluginId)
        XCTAssertEqual(failures.first?.sessionId, "session")
        XCTAssertEqual(failures.first?.reason, .presentationFailed)
    }

    func testExhaustionEmitsOneDiagnosticWhenEnabled() {
        let ux = RoktUX()
        ux.overlayMaxPresenterRetries = 0
        ux.scheduleOverlayRetry = { _, _ in
            XCTFail("must not retry after the budget is exhausted")
        }
        ux.topViewControllerProvider = { nil }
        var diagnostics: [RoktEventRequest] = []
        let eventService = get_mock_event_processor(useDiagnosticEvents: true, eventHandler: { event in
            if event.eventType == .SignalSdkDiagnostic {
                diagnostics.append(event)
            }
        })

        ux.attemptOverlayPresentation(eventService: eventService, onUnload: {}, present: { _ in
            XCTFail("must not present without a view controller")
        })

        XCTAssertEqual(diagnostics.count, 1)
        XCTAssertEqual(diagnosticValue(kErrorCode, in: diagnostics.first), kAPIExecuteErrorCode)
        XCTAssertEqual(diagnosticValue(kErrorStackTrace, in: diagnostics.first),
                       kOverlayNotPresentedMessage + " after 0 retries")
        XCTAssertEqual(diagnosticValue(kErrorSeverity, in: diagnostics.first), Severity.error.rawValue)
    }

    func testDeadlineExhaustionStopsBeforeAnotherResolutionAttempt() {
        let ux = RoktUX()
        var currentTime: TimeInterval = 0
        ux.overlayPresentationTimeProvider = { currentTime }
        var scheduledRetries = 0
        ux.scheduleOverlayRetry = { _, work in
            scheduledRetries += 1
            currentTime = ux.overlayPresenterRetryTimeout
            work()
        }
        var resolveCalls = 0
        ux.topViewControllerProvider = {
            resolveCalls += 1
            return nil
        }
        var diagnostics: [RoktEventRequest] = []
        let eventService = get_mock_event_processor(useDiagnosticEvents: true, eventHandler: { event in
            if event.eventType == .SignalSdkDiagnostic {
                diagnostics.append(event)
            }
        })
        var unloadCount = 0
        var failures: [RoktUXEvent.LayoutFailure] = []
        ux.onRoktEvent = { event in
            if let failure = event as? RoktUXEvent.LayoutFailure {
                failures.append(failure)
            }
        }

        ux.attemptOverlayPresentation(eventService: eventService, onUnload: {
            unloadCount += 1
        }, present: { _ in
            XCTFail("must not present after the deadline")
        })

        XCTAssertEqual(resolveCalls, 1)
        XCTAssertEqual(scheduledRetries, 1)
        XCTAssertEqual(unloadCount, 1)
        XCTAssertEqual(failures.count, 1)
        XCTAssertEqual(failures.first?.layoutId, mockPluginId)
        XCTAssertEqual(failures.first?.sessionId, "session")
        XCTAssertEqual(failures.first?.reason, .presentationFailed)
        XCTAssertEqual(diagnostics.count, 1)
    }

    func testTransitionCompletionAfterDeadlineDoesNotPresentStaleLayout() {
        let ux = RoktUX()
        var currentTime: TimeInterval = 0
        ux.overlayPresentationTimeProvider = { currentTime }
        let viewController = UIViewController()
        var resolveCalls = 0
        ux.topViewControllerProvider = {
            resolveCalls += 1
            return viewController
        }
        var transitionCompletion: (() -> Void)?
        ux.deferOverlayPresentation = { _, completion in
            transitionCompletion = completion
            return .registered
        }
        var unloadCount = 0
        var failures: [RoktUXEvent.LayoutFailure] = []
        ux.onRoktEvent = { event in
            if let failure = event as? RoktUXEvent.LayoutFailure {
                failures.append(failure)
            }
        }
        var presentedViewController: UIViewController?

        ux.attemptOverlayPresentation(eventService: nil, onUnload: {
            unloadCount += 1
        }, present: {
            presentedViewController = $0
        })
        currentTime = ux.overlayPresenterRetryTimeout
        transitionCompletion?()

        XCTAssertEqual(resolveCalls, 1)
        XCTAssertNil(presentedViewController)
        XCTAssertEqual(unloadCount, 1)
        XCTAssertEqual(failures.count, 1)
        XCTAssertEqual(failures.first?.reason, .presentationFailed)
    }

    func testRejectedTransitionRegistrationContinuesOnlyOnce() {
        let ux = RoktUX()
        let viewController = UIViewController()
        var resolveCalls = 0
        ux.topViewControllerProvider = {
            resolveCalls += 1
            return viewController
        }
        var transitionCompletions: [() -> Void] = []
        ux.deferOverlayPresentation = { _, completion in
            transitionCompletions.append(completion)
            return .rejected
        }
        var presentationCount = 0

        ux.attemptOverlayPresentation(eventService: nil, onUnload: {
            XCTFail("must not unload")
        }, present: { _ in
            presentationCount += 1
        })

        XCTAssertEqual(resolveCalls, 4)
        XCTAssertEqual(transitionCompletions.count, 3)
        XCTAssertEqual(presentationCount, 1)

        transitionCompletions.forEach { $0() }

        XCTAssertEqual(resolveCalls, 4)
        XCTAssertEqual(presentationCount, 1)
    }

    private func diagnosticValue(_ name: String, in event: RoktEventRequest?) -> String? {
        event?.eventData.first(where: { $0.name == name })?.value
    }
}
