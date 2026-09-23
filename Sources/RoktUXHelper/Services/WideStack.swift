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
        // Inheriting the caller's QoS keeps the worker at the priority the work was requested at.
        // Note that `DispatchSemaphore` does not donate priority, so a caller that outranks the
        // inherited value can end up waiting on lower-priority work; flooring the QoS here would be
        // the remedy if that ever shows up in a measurement.
        thread.qualityOfService = Thread.current.qualityOfService
        thread.start()

        semaphore.wait()

        guard let result else { throw Failure.noResult }
        return try result.get()
    }
}
