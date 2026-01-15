import Testing
@testable import kenv

@Suite("Shell Quoting Tests")
struct ShellQuotingTests {

    @Test("Simple alphanumeric values are not quoted")
    func simpleValues() {
        #expect(shellQuote("hello") == "hello")
        #expect(shellQuote("ABC123") == "ABC123")
        #expect(shellQuote("test_value") == "test_value")
        #expect(shellQuote("path/to/file") == "path/to/file")
    }

    @Test("Values with spaces are quoted")
    func valuesWithSpaces() {
        #expect(shellQuote("hello world") == "'hello world'")
        #expect(shellQuote("two  spaces") == "'two  spaces'")
    }

    @Test("Values with special shell characters are quoted")
    func specialCharacters() {
        #expect(shellQuote("$HOME") == "'$HOME'")
        #expect(shellQuote("foo;bar") == "'foo;bar'")
        #expect(shellQuote("a&b") == "'a&b'")
        #expect(shellQuote("a|b") == "'a|b'")
        #expect(shellQuote("a>b") == "'a>b'")
        #expect(shellQuote("a<b") == "'a<b'")
        #expect(shellQuote("(test)") == "'(test)'")
        #expect(shellQuote("`cmd`") == "'`cmd`'")
    }

    @Test("Values with single quotes use escape sequence")
    func singleQuotes() {
        #expect(shellQuote("it's") == "'it'\\''s'")
        #expect(shellQuote("'quoted'") == "''\\''quoted'\\'''")
    }

    @Test("Values with newlines are quoted")
    func newlines() {
        #expect(shellQuote("line1\nline2") == "'line1\nline2'")
    }

    @Test("Empty string is quoted")
    func emptyString() {
        #expect(shellQuote("") == "''")
    }

    @Test("Format output line without export")
    func formatWithoutExport() {
        #expect(formatEnvLine(name: "KEY", value: "value", export: false) == "KEY=value")
        #expect(formatEnvLine(name: "KEY", value: "hello world", export: false) == "KEY='hello world'")
    }

    @Test("Format output line with export")
    func formatWithExport() {
        #expect(formatEnvLine(name: "KEY", value: "value", export: true) == "export KEY=value")
        #expect(formatEnvLine(name: "KEY", value: "hello world", export: true) == "export KEY='hello world'")
    }
}
