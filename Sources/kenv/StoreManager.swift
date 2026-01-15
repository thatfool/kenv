import Foundation

/// Manages named secret stores in the login keychain.
struct StoreManager: Sendable {
    private let keychain: KeychainProtocol
    private let servicePrefix: String

    init(keychain: KeychainProtocol = Keychain.shared, servicePrefix: String = "kenv.") {
        self.keychain = keychain
        self.servicePrefix = servicePrefix
    }

    /// The service name consists of the prefix and the store name.
    private func serviceName(for store: String) -> String {
        servicePrefix + store
    }

    /// Load a store from the keychain in an existing session.
    private func loadStore(_ name: String, from session: AuthenticatedKeychain) throws -> Store {
        do {
            let data = try session.load(service: serviceName(for: name))
            guard let json = String(data: data, encoding: .utf8) else {
                throw StoreError.keychainError(.encodingError)
            }
            return try Store.fromJSON(json)
        } catch let error as KeychainError {
            if case .itemNotFound = error {
                throw StoreError.storeNotFound(name)
            }
            throw StoreError.keychainError(error)
        }
    }

    /// Write a store to the keychain in an existing session.
    private func saveStore(_ name: String, store: Store, to session: AuthenticatedKeychain) throws {
        let json = try store.toJSON()
        guard let data = json.data(using: .utf8) else {
            throw StoreError.keychainError(.encodingError)
        }
        do {
            try session.save(service: serviceName(for: name), data: data)
        } catch let error as KeychainError {
            throw StoreError.keychainError(error)
        }
    }

    /// Delete a store in an existing session.
    private func deleteStore(_ name: String, from session: AuthenticatedKeychain) throws {
        do {
            try session.delete(service: serviceName(for: name))
        } catch let error as KeychainError {
            if case .itemNotFound = error {
                throw StoreError.storeNotFound(name)
            }
            throw StoreError.keychainError(error)
        }
    }

    /// Delete a store.
    func deleteStore(_ name: String) throws {
        try keychain.withAuthentication { session in
            try deleteStore(name, from: session)
        }
    }

    /// List the stores sharing the prefix.
    func listStores() throws -> [String] {
        do {
            return try keychain.listServices(withPrefix: servicePrefix)
        } catch let error as KeychainError {
            throw StoreError.keychainError(error)
        }
    }

    /// Set a variable in a given store.
    func setVariable(store storeName: String, name: String, value: String) throws {
        guard isValidEnvironmentVariableName(name) else {
            throw StoreError.invalidVariableName(name)
        }

        try keychain.withAuthentication { session in
            var store: Store
            do {
                store = try loadStore(storeName, from: session)
            } catch StoreError.storeNotFound {
                store = Store()
            }

            store.set(name, value: value)
            try saveStore(storeName, store: store, to: session)
        }
    }

    /// Unset a variable in a given store, and delete the keychain if it is now empty.
    func unsetVariable(store storeName: String, name: String) throws {
        try keychain.withAuthentication { session in
            var store = try loadStore(storeName, from: session)
            store.unset(name)

            if store.isEmpty {
                try deleteStore(storeName, from: session)
            } else {
                try saveStore(storeName, store: store, to: session)
            }
        }
    }

    /// Retrieve a variable from a given store.
    func getVariable(store storeName: String, name: String) throws -> String? {
        try keychain.withAuthentication { session in
            let store = try loadStore(storeName, from: session)
            return store.get(name)
        }
    }

    /// Retrieve all variables from a given store.
    func getAllVariables(store storeName: String) throws -> [String: String] {
        try keychain.withAuthentication { session in
            let store = try loadStore(storeName, from: session)
            return store.allVariables
        }
    }
}

/// An error during an interaction with a store or the keychain.
enum StoreError: Error, LocalizedError {
    case storeNotFound(String)
    case invalidVariableName(String)
    case keychainError(KeychainError)

    var errorDescription: String? {
        switch self {
        case .storeNotFound(let name):
            return "Store '\(name)' not found"
        case .invalidVariableName(let name):
            return "Invalid environment variable name: '\(name)'"
        case .keychainError(let error):
            return error.errorDescription
        }
    }
}
