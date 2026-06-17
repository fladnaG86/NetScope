import Foundation

/// Runs a Process asynchronously without blocking the calling thread.
/// The caller sets up standardOutput/standardError before calling this.
/// Uses a background thread for waitUntilExit() to avoid blocking the cooperative pool.
enum AsyncProcess {
    /// Runs the process and waits for it to exit on a background thread.
    /// Returns the termination status, or nil if the process failed to launch.
    /// The caller is responsible for reading stdout/stderr from the Pipe after this returns.
    @discardableResult
    static func run(_ process: Process) async -> Int32? {
        do {
            try process.run()
        } catch {
            print("[AsyncProcess] Failed to launch \(process.executableURL?.path ?? "?"): \(error)")
            return nil
        }
        // waitUntilExit() blocks until the process finishes — run on a background thread.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                continuation.resume()
            }
        }
        return process.terminationStatus
    }
}