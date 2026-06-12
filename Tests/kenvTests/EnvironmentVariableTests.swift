import Testing
@testable import kenv

@Suite("Environment Variable Validation Tests")
struct EnvironmentVariableTests {

    @Test("Valid environment variable names")
    func validNames() {
        #expect(isValidEnvironmentVariableName("API_KEY"))
        #expect(isValidEnvironmentVariableName("DATABASE_URL"))
        #expect(isValidEnvironmentVariableName("MY_VAR_123"))
        #expect(isValidEnvironmentVariableName("_PRIVATE"))
        #expect(isValidEnvironmentVariableName("a"))
        #expect(isValidEnvironmentVariableName("A"))
        #expect(isValidEnvironmentVariableName("_"))
    }

    @Test("Invalid environment variable names - starts with digit")
    func invalidStartsWithDigit() {
        #expect(!isValidEnvironmentVariableName("123_VAR"))
        #expect(!isValidEnvironmentVariableName("1"))
    }

    @Test("Invalid environment variable names - contains invalid characters")
    func invalidCharacters() {
        #expect(!isValidEnvironmentVariableName("MY-VAR"))
        #expect(!isValidEnvironmentVariableName("MY.VAR"))
        #expect(!isValidEnvironmentVariableName("MY VAR"))
        #expect(!isValidEnvironmentVariableName("MY@VAR"))
        #expect(!isValidEnvironmentVariableName(""))
    }

    @Test("Invalid environment variable names - non-ASCII")
    func invalidNonASCII() {
        #expect(!isValidEnvironmentVariableName("ÜBER_KEY"))
        #expect(!isValidEnvironmentVariableName("CAFÉ"))
        #expect(!isValidEnvironmentVariableName("変数"))
        #expect(!isValidEnvironmentVariableName("MY_VAR_１２３"))
    }
}
