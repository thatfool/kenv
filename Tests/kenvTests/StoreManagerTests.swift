import Testing
@testable import kenv

@Suite("StoreManager Tests")
struct StoreManagerTests {
    let mockKeychain = MockKeychain()

    @Test("Set and get variable")
    func setAndGet() throws {
        let manager = StoreManager(keychain: mockKeychain)

        try manager.setVariable(store: "test", name: "API_KEY", value: "secret")

        let value = try manager.getVariable(store: "test", name: "API_KEY")
        #expect(value == "secret")
    }

    @Test("Set creates store if it doesn't exist")
    func setCreatesStore() throws {
        let manager = StoreManager(keychain: mockKeychain)

        try manager.setVariable(store: "newstore", name: "KEY", value: "value")

        let stores = try manager.listStores()
        #expect(stores.contains("newstore"))
    }

    @Test("Set overwrites existing variable")
    func setOverwrites() throws {
        let manager = StoreManager(keychain: mockKeychain)

        try manager.setVariable(store: "test", name: "KEY", value: "first")
        try manager.setVariable(store: "test", name: "KEY", value: "second")

        let value = try manager.getVariable(store: "test", name: "KEY")
        #expect(value == "second")
    }

    @Test("Set rejects invalid variable name")
    func setRejectsInvalid() throws {
        let manager = StoreManager(keychain: mockKeychain)

        #expect(throws: StoreError.self) {
            try manager.setVariable(store: "test", name: "123invalid", value: "value")
        }
    }

    @Test("Unset removes variable")
    func unsetRemoves() throws {
        let manager = StoreManager(keychain: mockKeychain)

        try manager.setVariable(store: "test", name: "KEY1", value: "v1")
        try manager.setVariable(store: "test", name: "KEY2", value: "v2")

        try manager.unsetVariable(store: "test", name: "KEY1")

        let value = try manager.getVariable(store: "test", name: "KEY1")
        #expect(value == nil)

        let remaining = try manager.getVariable(store: "test", name: "KEY2")
        #expect(remaining == "v2")
    }

    @Test("Unset deletes store when last variable removed")
    func unsetDeletesEmptyStore() throws {
        let manager = StoreManager(keychain: mockKeychain)

        try manager.setVariable(store: "test", name: "ONLY_KEY", value: "value")
        try manager.unsetVariable(store: "test", name: "ONLY_KEY")

        let stores = try manager.listStores()
        #expect(!stores.contains("test"))
    }

    @Test("Get all variables returns all keys")
    func getAllVariables() throws {
        let manager = StoreManager(keychain: mockKeychain)

        try manager.setVariable(store: "test", name: "ZEBRA", value: "z")
        try manager.setVariable(store: "test", name: "APPLE", value: "a")
        try manager.setVariable(store: "test", name: "MANGO", value: "m")

        let all = try manager.getAllVariables(store: "test")
        #expect(all["ZEBRA"] == "z")
        #expect(all["APPLE"] == "a")
        #expect(all["MANGO"] == "m")
    }

    @Test("Delete store removes it")
    func deleteStore() throws {
        let manager = StoreManager(keychain: mockKeychain)

        try manager.setVariable(store: "todelete", name: "KEY", value: "value")
        try manager.deleteStore("todelete")

        #expect(throws: StoreError.self) {
            _ = try manager.getAllVariables(store: "todelete")
        }
    }

    @Test("Delete nonexistent store throws error")
    func deleteNonexistent() throws {
        let manager = StoreManager(keychain: mockKeychain)

        #expect(throws: StoreError.self) {
            try manager.deleteStore("nonexistent")
        }
    }

    @Test("List stores returns all store names")
    func listStores() throws {
        let manager = StoreManager(keychain: mockKeychain)

        try manager.setVariable(store: "store1", name: "KEY", value: "v")
        try manager.setVariable(store: "store2", name: "KEY", value: "v")
        try manager.setVariable(store: "store3", name: "KEY", value: "v")

        let stores = try manager.listStores()
        #expect(stores == ["store1", "store2", "store3"])
    }

    @Test("Get from nonexistent store throws error")
    func getNonexistent() throws {
        let manager = StoreManager(keychain: mockKeychain)

        #expect(throws: StoreError.self) {
            _ = try manager.getAllVariables(store: "nonexistent")
        }
    }
}
