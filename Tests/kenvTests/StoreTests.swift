import Testing
@testable import kenv

@Suite("Store Tests")
struct StoreTests {

    @Test("Empty store serializes to empty JSON object")
    func emptyStoreSerialization() throws {
        let store = Store()
        let json = try store.toJSON()
        #expect(json == "{}")
    }

    @Test("Store with variables serializes to JSON")
    func storeWithVariables() throws {
        var store = Store()
        store.set("API_KEY", value: "secret123")
        store.set("DATABASE_URL", value: "postgres://localhost")

        let json = try store.toJSON()
        let restored = try Store.fromJSON(json)

        #expect(restored.get("API_KEY") == "secret123")
        #expect(restored.get("DATABASE_URL") == "postgres://localhost")
    }

    @Test("Store preserves values with special characters")
    func specialCharacters() throws {
        var store = Store()
        store.set("MULTILINE", value: "line1\nline2\nline3")
        store.set("QUOTES", value: "it's a \"test\"")
        store.set("UNICODE", value: "émoji 🎉")

        let json = try store.toJSON()
        let restored = try Store.fromJSON(json)

        #expect(restored.get("MULTILINE") == "line1\nline2\nline3")
        #expect(restored.get("QUOTES") == "it's a \"test\"")
        #expect(restored.get("UNICODE") == "émoji 🎉")
    }

    @Test("Store unset removes variable")
    func unsetVariable() throws {
        var store = Store()
        store.set("KEY", value: "value")
        #expect(store.get("KEY") == "value")

        store.unset("KEY")
        #expect(store.get("KEY") == nil)
    }

    @Test("Store lists all variable names")
    func listVariables() throws {
        var store = Store()
        store.set("ZEBRA", value: "z")
        store.set("APPLE", value: "a")
        store.set("MANGO", value: "m")

        let names = store.variableNames.sorted()
        #expect(names == ["APPLE", "MANGO", "ZEBRA"])
    }
}
