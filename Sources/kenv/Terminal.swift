import Foundation

/// Controls terminal echo for secret input.
/// The saved attributes are global so a SIGINT handler can restore them
/// if the user interrupts data entry while echo is disabled.
enum Terminal {
    nonisolated(unsafe) private static var originalAttributes: termios?

    /// Disables echo on standard input. Newlines remain visible so line-based
    /// entry still gives feedback when return is pressed.
    static func disableEcho() throws {
        var attributes = termios()
        guard tcgetattr(STDIN_FILENO, &attributes) == 0 else {
            throw RuntimeError("Failed to read terminal attributes")
        }
        originalAttributes = attributes

        attributes.c_lflag &= ~tcflag_t(ECHO)
        attributes.c_lflag |= tcflag_t(ECHONL)
        guard tcsetattr(STDIN_FILENO, TCSAFLUSH, &attributes) == 0 else {
            originalAttributes = nil
            throw RuntimeError("Failed to disable terminal echo")
        }

        signal(SIGINT) { _ in
            Terminal.restoreEcho()
            raise(SIGINT)
        }
    }

    /// Restores the attributes saved by disableEcho.
    static func restoreEcho() {
        guard var attributes = originalAttributes else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &attributes)
        originalAttributes = nil
        signal(SIGINT, SIG_DFL)
    }
}
