import Foundation

/// Utility to verify that a string is a valid name for an environment variable.
func isValidEnvironmentVariableName(_ name: String) -> Bool {
    guard !name.isEmpty else { return false }

    let validChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))

    for (index, character) in name.unicodeScalars.enumerated() {
        if !validChars.contains(character) {
            return false
        }
        // First character cannot be a digit
        if index == 0 && CharacterSet.decimalDigits.contains(character) {
            return false
        }
    }

    return true
}
