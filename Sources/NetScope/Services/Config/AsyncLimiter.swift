import Foundation

/// Async-compatible concurrency limiter (replaces DispatchSemaphore in async contexts).
actor ConcurrencyLimiter {
    private let maxConcurrent: Int
    private var running: Int = 0

    init(_ maxConcurrent: Int) {
        self.maxConcurrent = maxConcurrent
    }

    func acquire() {
        running += 1
    }

    func release() {
        running -= 1
    }

    var isFull: Bool {
        running >= maxConcurrent
    }

    /// Waits until a slot is available, then acquires it.
    func waitUntilAvailable() async {
        while running >= maxConcurrent {
            try? await Task.sleep(for: .milliseconds(50))
        }
        running += 1
    }
}
