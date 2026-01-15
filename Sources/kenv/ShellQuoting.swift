import Foundation

private let shellSpecialCharacters = CharacterSet(charactersIn: " \t\n\r\"'`$\\!#&|;<>(){}[]?*~")

/// Utility to quote strings for use in shell scripts.
/// Used by the get command.
func shellQuote(_ value: String) -> String {
    // Empty string needs quotes
    if value.isEmpty {
        return "''"
    }

    // Check if quoting is needed for special characters
    let needsQuoting = value.unicodeScalars.contains { shellSpecialCharacters.contains($0) }

    if !needsQuoting {
        return value
    }

    // Use single quotes, escaping any single quotes in the value
    // To escape a single quote: end the string, add \', start a new string
    var result = "'"
    for char in value {
        if char == "'" {
            result += "'\\''"
        } else {
            result.append(char)
        }
    }
    result += "'"

    return result
}

/// Utility to format an entire line as a shell variable assignment, either with export or without.
func formatEnvLine(name: String, value: String, export: Bool) -> String {
    let quotedValue = shellQuote(value)
    if export {
        return "export \(name)=\(quotedValue)"
    } else {
        return "\(name)=\(quotedValue)"
    }
}
