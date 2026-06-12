import Foundation

/// An exclusive advisory file lock, used to serialize store modifications
/// across concurrent kenv processes. The kernel releases the lock when the
/// process exits, so a crash cannot leave it stuck.
struct FileLock {
    private let descriptor: Int32

    /// Acquires the lock, blocking until it is available.
    init(name: String) throws {
        let path = try FileLock.lockDirectory().appendingPathComponent(name).path
        descriptor = open(path, O_CREAT | O_RDWR, 0o600)
        guard descriptor >= 0 else {
            throw RuntimeError("Failed to open lock file '\(path)': \(String(cString: strerror(errno)))")
        }
        guard flock(descriptor, LOCK_EX) == 0 else {
            let lockErrno = errno
            close(descriptor)
            throw RuntimeError("Failed to acquire lock '\(path)': \(String(cString: strerror(lockErrno)))")
        }
    }

    /// Releases the lock.
    func unlock() {
        flock(descriptor, LOCK_UN)
        close(descriptor)
    }

    private static func lockDirectory() throws -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw RuntimeError("Failed to locate application support directory")
        }
        let directory = base.appendingPathComponent("kenv", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

/// Runs an operation while holding an exclusive lock with the given name.
func withFileLock<T>(name: String, _ operation: () throws -> T) throws -> T {
    let lock = try FileLock(name: name)
    defer { lock.unlock() }
    return try operation()
}
