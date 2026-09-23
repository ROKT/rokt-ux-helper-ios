import Foundation

/// Runs work synchronously on a dedicated thread with an enlarged stack.
///
/// Both the experience decode and the layout transform are recursive descents whose stack cost
/// grows with how deeply the payload nests, and both run on the caller's thread — the app main
/// thread, which is 1 MB on device against 8 MB in the simulator. Moving only the recursion onto a
/// wide stack keeps the caller's semantics intact: it still blocks until the work finishes, so
/// event ordering and re-entrancy are unchanged.
@available(iOS 13, *)
enum WideStack {

    static let defaultStackSize = 8 * 1024 * 1024

    enum Failure: Error {
        /// The worker finished without producing a result. Unreachable — the semaphore is only
        /// signalled from the worker's `defer`, which runs after `result` has been written.
        case noResult
    }

    static func run<T>(named name: String,
                       stackSize: Int = defaultStackSize,
                       _ body: @escaping () throws -> T) throws -> T {
        var result: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        let thread = Thread {
            defer { semaphore.signal() }
            result = Result { try body() }
        }
        thread.name = name
        // Must be set before `start()`; it is ignored afterwards.
        thread.stackSize = max(thread.stackSize, stackSize)
        // The worker inherits the caller's QoS, except on the main thread, which reports
        // `.default` even though the scheduler treats it as interactive. Since `DispatchSemaphore`
        // donates no priority, taking that value literally would leave the main thread blocked on a
        // worker the scheduler is free to deprioritise.
        thread.qualityOfService = Thread.isMainThread ? .userInteractive : Thread.current.qualityOfService
        thread.start()

        semaphore.wait()

        guard let result else { throw Failure.noResult }
        return try result.get()
    }
}
