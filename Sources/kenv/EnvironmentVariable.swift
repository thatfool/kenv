import Foundation

private let asciiLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
private let validFirstCharacters = CharacterSet(charactersIn: asciiLetters + "_")
private let validCharacters = CharacterSet(charactersIn: asciiLetters + "0123456789_")

/// Utility to verify that a string is a valid name for an environment variable.
/// Names are restricted to portable POSIX shell identifiers ([A-Za-z_][A-Za-z0-9_]*)
/// so that the output of `kenv get` can be used in any shell, e.g. with eval.
func isValidEnvironmentVariableName(_ name: String) -> Bool {
    guard !name.isEmpty else { return false }

    for (index, character) in name.unicodeScalars.enumerated() {
        if index == 0 {
            if !validFirstCharacters.contains(character) {
                return false
            }
        } else if !validCharacters.contains(character) {
            return false
        }
    }

    return true
}
